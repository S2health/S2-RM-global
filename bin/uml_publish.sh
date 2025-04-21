#!/bin/bash

# Extract UML from {product_name}-{component_root}-xx repo.

#
# ============== Definitions =============
#
product_name="S2"
component_root="RM"
def_dir_leader="$product_name-${component_root}-"
dir_leader=${def_dir_leader}

UML_EXTRACT="uml_generate_msa.sh"

USAGE="${0} [-nfuhrptv] [-m pub_hom_dir] [-l release] [component names]: generate publishing outputs; HTML by default 
  -f : force document regeneration
  -n : turn off default directory pattern ${def_dir_leader}
  -u : force UML regeneration
  -h : output this help
  -k : keep (previous) output, i.e. don't delete
  -r : use remote CSS file location from website
  -p : generate PDF as well								
  -q : generate class name files qualified by package names
  -t : generate debug trace of asciidoctor-pdf back-end.
  -m dir : set a specific publishing home location; default is parent of specs dirs
  -l release : use a specific release e.g. 'Release-1.0.3' - only use with a single component e.g. 'RM'
  -w : turn on missing attribute warnings
  -v : turn on asciidoctor verbose mode

  Component names are the XX part of specifications directories with names of the form
  ${def_dir_leader}XX; 

  Examples:
    ${0} AM                      # publish AM component using local CSS
    ${0} -r AM                   # publish AM component using remote CSS
    ${0} -r                      # publish all components using remote CSS
    ${0} -l Release-2.0.5 -r AM  # publish AM components as Release-2.0.5, using remote CSS
"

NO_COMPONENTS_ERR="No components found. A 'component' is a name like 'AM', 'RM' etc, 
   that forms the final part of a directory with a name of the form '${def_dir_leader}XX'
"

COMPONENTS_RELEASE_ERR="When specifying a fixed release, only one component may be specified
"

#
# ============== functions =============
#

usage() { echo "$USAGE" 1>&2; exit 1; }

#
# ================== main =================
#

# ------------- static vars --------------
year=`date +%G`
global_ref_repo=global
uml_gen_dir=docs/UML/classes
s2_pkg_depth=5
s2_link_template='/releases/\${component_prefix}\${component}/{\${component_lower}_release}/docs/\${spec_name}.html'

manifest_file=manifest.json
manifest_vars_file=manifest_vars.adoc

# relative location of UML directory under any S2-XX directory
uml_source_dir=computable/UML
uml_root_package=${product_name,,}	# = product name in lower case

specs_root_uri=https://platform.s2health.org
specs_css_uri=$specs_root_uri/css

force_generate=false

#
# ================== main =================
#

# ---------- get the options ----------
while getopts "fhpuvkm:c:" o; do
    case "${o}" in
        c)
            component_package=$OPTARG
            ;;

        n)
            dir_leader=""
            ;;
        f)
            force_generate=true
            ;;
        u)
            uml_force_generate=true
            ;;
        k)
            keep_output=true
            ;;

        p)
            gen_pdf=true
            ;;

        h)
            usage
            ;;

        m)
            pub_home=$OPTARG
            ;;

        v)
            verbose_mode=true
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

# specifications root dir: this directory must contain clones of all the S2-XX repos
# as well as the adl-antlr repo.
work_root=$PWD
pub_home=${pub_home:-$PWD}
echo "setting pub_home to $pub_home"
echo "setting work_root to $work_root"

# directory of S2-global repo clone from a S2-XX/docs/xxx directory
# resolved during processing of this script
ref_dir=$pub_home//$dir_leader$global_ref_repo
echo "setting ref_dir to $ref_dir"

# set the following only for re-publishing old releases
base_dir=$pub_home/${dir_leader}BASE
echo "setting base_dir to $base_dir"

# see if there are individual args like 'S2-RM-BASE', 'S2-RM-ENTITY' etc
if [ $# -ne 1 ]; then
	echo "$NO_COMPONENTS_ERR"
	exit 2
else
	component="$1"
fi


# ---------- do the publishing ----------

echo "========= cd $component =========="
cd "$component" || exit 1

# re-run UML extractor to create UML doc files if applicable
if [ -d $uml_source_dir ]; then

  uml_file="${uml_source_dir}/${component}.mdzip"

  # e.g. S2-RM-ENTITY -> ENTITY
  if [ -z ${component_package} ]; then
    component_package="${component##*-}"
  fi

  # e.g. S2-RM-ENTITY -> S2-RM-
  component_prefix="$(echo "$component" | sed 's/[^-]*$//')"

  echo "checking UML file $uml_file"

  # e.g. uml_generate_msa.sh -d svg -k <link_tpl> -p 5 -r s2 -q -c ENTITY -P S2-RM- -o docs/UML S2-RM-ENTITY.mdzip
  uml_regen_cmd="$ref_dir/bin/$UML_EXTRACT -d svg -k $s2_link_template -p $s2_pkg_depth -r $uml_root_package -q -c $component_package -P $component_prefix -o docs/UML $uml_file"

  if [[ "$keep_output" != true ]]; then
    rm -f docs/UML/classes/*.*
    rm -f docs/UML/diagrams/*.*
  fi

  echo "$uml_regen_cmd"
  eval "$uml_regen_cmd"

fi

