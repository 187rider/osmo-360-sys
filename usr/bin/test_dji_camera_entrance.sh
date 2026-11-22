#! /bin/bash

readonly TRUE=0
readonly FALSE=1
readonly RETRY_INFINITE=-1
readonly RETRY_MAX=1800
readonly RETRY_INTERVAL=1
readonly INPUT_DATA_NOT_CHANGE_MAX=10
#patch_info file number threshold for precise_test
readonly PATCH_FILE_NR_MAX=3
readonly CONF_ITEM_DELIMITER=","
readonly KEY_VALUE_DELIMITER="="
readonly TEST_GROUP_CONF_DIR="/system/etc"
readonly WHITELIST_CONF_DIR="/system/etc"
readonly TEST_CASES_CONF_DIR="/system/etc"
readonly STRENGTH_DELIMITER="strength="
#todo: passing PATCH_INFO_DIR by QA
readonly PATCH_INFO_DIR="/system/etc/patch_info"
#precise_test enabling file
readonly PRECISE_TEST_CONF_PATH="/system/etc/cam_precise_test.conf"
#adding specific test repo in whitelist
readonly SPECIFIC_TEST_REPO_STR="specific_test_repo"

stress_test_enable=$FALSE
whitelist_enabled=$FALSE
precise_test_enabled=$FALSE
all_test_enabled=$FALSE
git_project_str=""
git_project_list=()
query_cmd=""
test_group_to_be_run=""
input_data_space_usage=-1
input_data_not_change_counter=0
sensor_name=""
patch_file_dir=""
patch_file_list=()
cam_test_type=""

test_group_list=()
test_program_list=()
test_timeout_list=()
src_data_git_list=()
src_data_path_list=()
des_data_path_list=()
log_file_list=()
gcov_file_list=()
skip_test_when_not_hit_whitelist_list=()
# if the test_group don't configure test_priority param, its test_priority will be blank.
# the lowest priority is used specifically for tested cases statistic, other test grouops can't configure test_priority param to lowest!
test_prio_list=(high mid low blank lowest)

show_usage()
{
    printf "Usage: %s [-p <git_project_list>] [-q test_seq] [-g <test_group>] [-r] [-h]\n" $0 >&2
    printf "Get test_group sequence:                       %s -p <dcamgit:git1,dcamgit:git2,shgit:gita,shgit:gitb,...> -q test_seq\n" $0 >&2
    printf "Run all test_group using whitelist:            %s -p <dcamgit:git1,dcamgit:git2,shgit:gita,shgit:gitb,...>\n" $0 >&2
    printf "Run all test_group without using whitelist:    %s\n" $0 >&2
    printf "Run single test_group using whitelist:         %s -p <dcamgit:git1,dcamgit:git2,shgit:gita,shgit:gitb,...> -g <test_group>\n" $0 >&2
    printf "\t-p <git_projects_list>        Specify changed git projects list.. if -p snapshot_test, it eaqual to -p all\n" >&2
    printf "\t-q test_seq                   Print test_group sequence to stdout without running any test.\n" >&2
    printf "\t-g <test_group>               Specify test_group to be run and it will export an env as CAM_TEST_ENV.\n" >&2
    printf "\t-r                            Enable stress test.\n" >&2
    printf "\t-h                            Show this help screen.\n" >&2
    printf "Example:\n" >&2
    printf "\t1. Get test_group sequence that need to be executed if git projects 'dcamgit:git1', 'dcamgit:git2', 'shgit:gita' and 'shgit:gitb' have been changed:\n" >&2
    printf "\t\t%s -p dcamgit:git1,dcamgit:git2,shgit:gita,shgit:gitb -q test_seq\n" $0 >&2
    printf "\n\t2. Get test_group sequence that need to be executed if all git projects have been changed:\n" >&2
    printf "\t\t%s -p all -q test_seq\n" $0 >&2
    printf "\n\t3. Run test_group sequences that need to be executed if git projects 'dcamgit:git1', 'dcamgit:git2', 'shgit:gita' and 'shgit:gitb' have been changed:\n" >&2
    printf "\t\t%s -p dcamgit:git1,dcamgit:git2,shgit:gita,shgit:gitb\n" $0 >&2
    printf "\n\t4. Run cht test_group using whitelist:\n" >&2
    printf "\t\t%s -p dcamgit:git1,dcamgit:git2,shgit:gita,shgit:gitb -g cht\n" $0 >&2
    printf "\n\t5. Run all non-interactive(i.e. don't need input data) test_group sequences unconditionally:\n" >&2
    printf "\t\t%s\n\n" $0 >&2
}

enable_stress_test()
{
    stress_test_enable=$TRUE
}

is_stress_test_enabled()
{
    return $stress_test_enable
}

get_test_script_dir()
{
    echo $(cd $(dirname $0) && pwd)
}

get_test_group_conf_dir()
{
    echo "$TEST_GROUP_CONF_DIR"
}

get_whitelist_conf_dir()
{
    echo "$WHITELIST_CONF_DIR"
}

get_precise_test_conf_path()
{
    echo "$PRECISE_TEST_CONF_PATH"
}

get_patch_info_dir()
{
    echo "$PATCH_INFO_DIR"
}

enable_whitelist()
{
    whitelist_enabled=$TRUE
}

is_whitelist_enabled()
{
    return $whitelist_enabled
}

enable_precise_test()
{
    precise_test_enabled=$TRUE
}

is_precise_test_enabled()
{
    return $precise_test_enabled
}

is_all_test_enabled()
{
    return $all_test_enabled
}

is_string_start_with()
{
    local str=$1
    local prefix=$2
    case "$str" in
        "$prefix"*)
                return $TRUE
                ;;
        *)
                return $FALSE
                ;;
    esac
}

is_string_contain()
{
    local str=$1
    local target=$2
    if test "${str#*$target*}" = "$str"; then
        return $FALSE
    else
        return $TRUE
    fi
}

is_number()
{
    local var=$1
    case ${var#[-+]} in
        *[!0-9]* | '')
            return $FALSE
            ;;
        *)
            return $TRUE
            ;;
    esac
}

trim_space()
{
    local str=$1
    str=${str#"${str%%[!$' \t']*}"}
    str=${str%"${str##*[!$' \t']}"}
    printf '%s' "$str"
}

is_string_blank()
{
    local str=$1
    str=$(trim_space "$str")
    test -z "$str"
}

is_git_project_all()
{
    local name=$1
    test "$name" = "all"
}

is_dir_exist()
{
    local file_dir=$1
    test -d "$file_dir"
}

is_file_no_empty()
{
    local file_name=$1
    test -s "$file_name"
}

check_git_project_name()
{
    local name=$1

    if is_string_blank "$name"; then
        return $FALSE
    fi

    if is_git_project_all "$name"; then
        return $TRUE
    fi

    if is_string_start_with "$name" "-"; then
        return $FALSE
    fi

    if ! is_string_contain "$name" ":"; then
        return $FALSE
    fi

    return $TRUE
}

parse_git_project_list()
{
    local str="$1"
    local delimiter=$2
    local i=0

    while test "$str"
    do
        local git=${str%%${delimiter}*}
        if ! check_git_project_name "$git"; then
            printf "%s: invalid git project name: '%s'\n" $0 "$git" >&2
            return $FALSE
        fi

        git_project_list[$i]="$git"

        if test "$str" = "$git"; then
            str=""
        else
            str="${str#*${delimiter}}"
        fi

        i=$(expr $i + 1)
    done

    return $TRUE
}

check_patch_info_file()
{
    local patch_file_dir=$1

    for file_name in $patch_file_dir/*
    do
        if ! is_file_no_empty $file_name; then
            printf "[ERR] Patch_info file:%s is empty\n" $file_name
            return $FALSE
        fi

        patch_file_list[$i]="$file_name"
        i=$(expr $i + 1)
    done

    if test $i -ge $PATCH_FILE_NR_MAX; then
        printf "[INF] Reach max patch_info file num, non-precise test will be executed\n"
        return $FALSE
    fi

    return $TRUE
}

prepare_precise_test()
{
    local file_dir="$1"
    local i=0

    if is_all_test_enabled; then
        printf "[INF] Executing snapshot test\n"
        return $TRUE
    fi

    if ! is_dir_exist "$file_dir"; then
        printf "[ERR] PATCH_INFO_DIR doesn't exist, so precise test feature is not available\n"
        return $TRUE
    fi

    if ! check_patch_info_file "$file_dir"; then
        return $TRUE
    fi

    printf "[INF] Enable precise test\n"
    enable_precise_test

    return $TRUE
}

get_whitelist_filename()
{
    local test_group=$1
    echo "whitelist_${test_group}.conf"
}

get_quick_test_script_name()
{
    local test_group=$1
    echo "test_dji_${test_group}_quick.sh"
}

get_full_test_script_name()
{
    local test_group=$1
    echo "test_dji_${test_group}.sh"
}

is_test_need_input_data()
{
    local test_group=$1
    local des_data_path=$(get_des_data_path $test_group)
    if test "$des_data_path"; then
        return $TRUE
    else
        return $FALSE
    fi
}

find_line_in_file()
{
    local word=$1
    local filename=$2
    local status
    #replace grep with fgrep for speeding up test_group loading
    busybox fgrep -w -- "${word}" "${filename}"
}

find_git_in_whitelist()
{
    local git=$1
    local whitelist_file=$2
    local line
    line=$(find_line_in_file $git $whitelist_file)
}

find_key_in_line()
{
    local key=$1
    local line=$2
    case "$line" in
        *"$key"*)
            return $TRUE
            ;;
        *)
            return $FALSE
            ;;
    esac
}

get_test_strength_all_git()
{
    local whitelist_file=$1
    local test_strength=1

    while read line
    do
    if find_key_in_line "${STRENGTH_DELIMITER}" "$line"; then
        value=${line#*${STRENGTH_DELIMITER}}
        if test $value -gt $test_strength ; then
            test_strength=$value
        fi
    fi
    done < $whitelist_file
    echo "$test_strength"
}

get_test_strength()
{
    local test_group=$1
    local dir=$(get_whitelist_conf_dir)
    local file=$(get_whitelist_filename "$test_group")
    local whitelist_file="$dir/$file"
    local i
    local test_strength=1
    local git_find_rlt=""

    if test -f "$whitelist_file"; then
    for i in "${!git_project_list[@]}"
    do
        local git=${git_project_list[$i]}
        if is_all_test_enabled; then
            test_strength="$(get_test_strength_all_git $whitelist_file)"
            break
        fi

        git_find_rlt="$(find_line_in_file $git $whitelist_file)"
        if find_key_in_line "${STRENGTH_DELIMITER}" "$git_find_rlt"; then
            value=${git_find_rlt#*${STRENGTH_DELIMITER}}
            if test $value -gt $test_strength ; then
                test_strength=$value
            fi
        fi
    done
    fi

    echo "$test_strength"
}

get_test_strength_precise()
{
    local whitelist_info=$1
    local all_patch_info_ctx=$2
    local wl_line
    local line_to_match
    local test_strength=1
    local ifs_old=$IFS
    IFS=$'\n'

    if find_key_in_line "$STRENGTH_DELIMITER" "$whitelist_info"; then
        for wl_line in $whitelist_info
        do
            if find_key_in_line "$STRENGTH_DELIMITER" "$wl_line"; then
                local tmp_strength=${wl_line#*${STRENGTH_DELIMITER}}

                line_to_match=${wl_line%%" ${STRENGTH_DELIMITER}"*}
                if find_key_in_line "$line_to_match" "$all_patch_info_ctx"; then
                    if [[ $tmp_strength -gt $test_strength ]]; then
                        test_strength=$tmp_strength
                    fi
                fi
            fi
        done
    fi
    IFS=$ifs_old

    echo "$test_strength"
}

is_sepc_test_repo_hit()
{
    local test_group=$1
    local sepcific_repo
    local dir=$(get_whitelist_conf_dir)
    local file=$(get_whitelist_filename "$test_group")
    local whitelist_file="$dir/$file"
    local i

    sepcific_repo=$(read_conf_item "$SPECIFIC_TEST_REPO_STR" "$whitelist_file")
    if is_string_blank "$sepcific_repo"; then
        return $FALSE
    fi

    for i in "${!git_project_list[@]}"
    do
        local git=${git_project_list[$i]}
        if is_string_contain "$git" "$sepcific_repo"; then
            return $TRUE
        fi
    done

    return $FALSE
}

is_patch_info_hit_precise()
{
    local whitelist_info=$1
    local all_patch_info_ctx=$2
    local test_group=$3
    local wl_line
    local line_to_match
    local ifs_old=$IFS

    if is_sepc_test_repo_hit "$test_group"; then
        return $TRUE
    fi

    IFS=$'\n'
    for wl_line in $whitelist_info
    do
        if find_key_in_line "$STRENGTH_DELIMITER" "$wl_line"; then
            line_to_match=${wl_line%%" ${STRENGTH_DELIMITER}"*}
        else
            line_to_match=$wl_line
        fi

        if find_key_in_line "$line_to_match" "$all_patch_info_ctx"; then
            return $TRUE
        fi
    done
    IFS=$ifs_old

    return $FALSE
}

is_whitelist_hit()
{
    local test_group=$1
    local dir=$(get_whitelist_conf_dir)
    local file=$(get_whitelist_filename "$test_group")
    local whitelist_file="$dir/$file"
    local i

    if is_sepc_test_repo_hit "$test_group"; then
        return $TRUE
    fi

    for i in "${!git_project_list[@]}"
    do
        local git=${git_project_list[$i]}
        if is_all_test_enabled; then
            return $TRUE
        fi

        if find_git_in_whitelist "$git" "$whitelist_file"; then
            return $TRUE
        fi
    done

    return $FALSE
}

read_conf_item()
{
    local key="$1"
    local file="$2"
    local line=""
    if line=$(find_line_in_file "$key" "$file"); then
        value=${line#*${KEY_VALUE_DELIMITER}}
        echo $value
    fi
}

copy_test_cases_strength_times()
{
    local copy_script="$(get_test_script_dir)/${test_group}_copy_cases.sh"

    if ! test -f $copy_script; then
        echo "$copy_script not exist!"
        return $FALSE
    else
        sh "$copy_script" $1
        printf "[INF] copy test group '%s' test cases %d times\n" "$test_group" "$1"
        return $TRUE
    fi
}

get_patch_info_ctx()
{
    local file_ctx
    local all_patch_info_ctx=""

    for file in "${patch_file_list[@]}"
    do
        file_ctx=$(cat $file)
        all_patch_info_ctx=$(echo "$all_patch_info_ctx""\n""$file_ctx")
    done

    echo "$all_patch_info_ctx"
}

query_precise_test_seq()
{
    local test_group_count=0
    local result=""
    local i
    local whitelist_file
    local whitelist_info
    local test_group
    local all_patch_info_ctx=$(get_patch_info_ctx)
    local dir=$(get_whitelist_conf_dir)
    local file_ctx
    local ifs_old=$IFS
    IFS=$'\n'

    for i in "${!test_group_list[@]}"
    do
        test_group=${test_group_list[$i]}
        whitelist_file="$dir/$(get_whitelist_filename "$test_group")"
        file_ctx=$(cat $whitelist_file)
        eval whitelist_ctx${test_group}=$(echo \$file_ctx)
    done

    local test_strength=1
    for i in "${!test_group_list[@]}"
    do
        test_group=${test_group_list[$i]}
        eval whitelist_info=\$whitelist_ctx${test_group}
        if ! is_patch_info_hit_precise "$whitelist_info" "$all_patch_info_ctx" "$test_group"; then
            if ! is_quick_test_script_exist "$test_group"; then
                continue
            fi
        else
            if ! is_full_test_script_exist "$test_group"; then
                printf "%s: error: full test script '%s' doesn't exist\n" $0 "$(get_full_test_script_name)" >&2
                return $FALSE
            fi
        fi

        if is_stress_test_enabled; then
            test_strength=$(get_test_strength_precise "$whitelist_info" "$all_patch_info_ctx")
            if test $test_strength -gt 1 ; then
                test_timeout_list[$i]=`expr ${test_timeout_list[$i]} \* $test_strength`
            fi
        fi

        result+="test_group: ${test_group_list[$i]}"
        result+=", test_program: ${test_program_list[$i]}"
        result+=", timeout: ${test_timeout_list[$i]}"
        result+=", src_data_git: ${src_data_git_list[$i]}"
        result+=", src_data_path: ${src_data_path_list[$i]}"
        result+=", des_data_path: ${des_data_path_list[$i]}"
        result+=", log_file: ${log_file_list[$i]}"
        result+=", gcov_file: ${gcov_file_list[$i]}"
        result+="\n"

        test_group_count=$(expr $test_group_count + 1)
    done
    IFS=$ifs_old

    echo "total_test_group_count: $test_group_count\n$result"

    return $TRUE
}

query_test_seq()
{
    if ! is_whitelist_enabled; then
        printf "%s: git project list missing while querying test sequence\n" $0 >&2
        return $FALSE
    fi

    local test_group_count=0
    local result=""
    local i

    for i in "${!test_group_list[@]}"
    do
        local test_group=${test_group_list[$i]}
        local test_strength=1
        if ! is_whitelist_hit "$test_group"; then
            if ! is_quick_test_script_exist "$test_group"; then
                continue
            fi
        else
            if ! is_full_test_script_exist "$test_group"; then
                printf "%s: error: full test script '%s' doesn't exist\n" $0 "$(get_full_test_script_name $test_group)" >&2
                return $FALSE
            fi
        fi

        if is_stress_test_enabled; then
            test_strength="$(get_test_strength $test_group)"
            if test $test_strength -gt 1 ; then
                test_timeout_list[$i]=`expr ${test_timeout_list[$i]} \* $test_strength`
            fi
        fi

        result+="test_group: ${test_group_list[$i]}"
        result+=", test_program: ${test_program_list[$i]}"
        result+=", timeout: ${test_timeout_list[$i]}"
        result+=", src_data_git: ${src_data_git_list[$i]}"
        result+=", src_data_path: ${src_data_path_list[$i]}"
        result+=", des_data_path: ${des_data_path_list[$i]}"
        result+=", log_file: ${log_file_list[$i]}"
        result+=", gcov_file: ${gcov_file_list[$i]}"
        result+="\n"

        test_group_count=$(expr $test_group_count + 1)
    done

    echo "total_test_group_count: $test_group_count\n$result"

    return $TRUE
}

handle_query()
{
    local cmd=$1

    case $cmd in
        test_seq)
            query_cmd="$cmd"
            return $TRUE
            ;;
        *)
            printf "%s: unexpected query cmd: %s\n" $0 $cmd >&2
            return $FALSE
            ;;
    esac
}

check_test_group_name()
{
    local name=$1

    if is_string_blank "$name"; then
        printf "[ERR] test_group name is blank\n" >&2
        return $FALSE
    fi

    if is_string_start_with "$name" "-"; then
        return $FALSE
    fi

    return $TRUE
}

set_test_group_to_be_run()
{
    local test_group=$1

    if ! check_test_group_name "$test_group"; then
        printf "%s: invalid test_group name: '%s'\n" $0 "$test_group" >&2
        return $FALSE
    fi

    test_group_to_be_run="$test_group"
    return $TRUE
}

check_sensor_name()
{
    local name=$1

    if is_string_blank "$name"; then
        printf "[ERR] sensor name is blank\n" >&2
        return $FALSE
    fi

    return $TRUE
}

set_sensor_name()
{
    local name=$1

    if ! check_sensor_name "$name"; then
        printf "%s: invalid sensor name: '%s'\n" $0 "$name" >&2
        return $FALSE
    fi

    sensor_name="$name"
    printf "%s:sensor name: '%s'\n" $0 $sensor_name >&2
    return $TRUE
}

parse_cmd_line()
{
    local OPTIND
    local option
    local arg
    while getopts ":p:q:g:hs:r" option
    do
        case $option in
            g)
                if ! set_test_group_to_be_run "$OPTARG"; then
                    return $FALSE
                fi
                ;;
            h)
                show_usage
                exit $TRUE
                ;;
            p)
                local arg="$OPTARG"
                if [[ "$arg" == "snapshot_test" || "$arg" == "breadth_test" ]]; then
                    cam_test_type=$arg
                    arg="all"
                fi
                if is_git_project_all "$arg"; then
                    all_test_enabled=$TRUE
                fi
                enable_whitelist
                git_project_str="$arg"
                ;;
            q)
                if ! handle_query "$OPTARG"; then
                    return $FALSE
                fi
                ;;
            r)
                enable_stress_test
                ;;
            s)
                local arg="$OPTARG"
                if ! set_sensor_name "$arg"; then
                    return $FALSE
                fi
                ;;
            \:)
                printf "%s: argument missing from -%s option\n" $0 $OPTARG >&2
                return $FALSE
                ;;
            \?)
                printf "%s: unknown option: -%s\n" $0 $OPTARG >&2
                return $FALSE
                ;;
        esac
    done

    shift $(expr $OPTIND - 1)
    if test $# -gt 0; then
        printf "%s: unknown non-option parameter: %s\n" $0 $1 >&2
        return $FALSE
    fi

    return $TRUE
}

get_quick_test_script_path()
{
    local test_group=$1
    local script_path="$(get_test_script_dir)/$(get_quick_test_script_name $test_group)"
    echo $script_path
}

is_quick_test_script_exist()
{
    printf "not support any quick test now! \n"
    return $FALSE
}

run_quick_test()
{
    local test_group=$1
    local script_path="$(get_quick_test_script_path $test_group)"
    if ! test -f "$script_path"; then
        printf "%s: quick test script '%s' ignored: doesn't exist\n" "$0" "$script_path" >&2
        return $FALSE
    fi

    printf "[INF] Running quick test script '%s' ...\n" "$script_path"
    sh "$script_path" $sensor_name

    return $TRUE
}

get_full_test_script_path()
{
    local test_group=$1
    local script_path="$(get_test_script_dir)/$(get_full_test_script_name $test_group)"
    echo $script_path
}

is_full_test_script_exist()
{
    local test_group=$1
    local script_path="$(get_full_test_script_path $test_group)"
    test -f "$script_path"
}

run_full_test()
{
    local test_group=$1
    local test_strength=1
    local script_path="$(get_full_test_script_path $test_group)"
    if ! test -f "$script_path"; then
        printf "%s: full test script '%s' ignored: doesn't exist\n" "$0" "$script_path" >&2
        return $FALSE
    fi

    if is_stress_test_enabled; then
        #if is in single test_group running, need to prepare precise test for getting test strength
        if test "$test_group_to_be_run"; then
            if ! parse_git_project_list "$git_project_str" $CONF_ITEM_DELIMITER; then
                return $FALSE
            fi

            if test -e "$(get_precise_test_conf_path)"; then
                if  ! prepare_precise_test "$(get_patch_info_dir)"; then
                    return $FALSE
                fi
            fi
        fi

        if ! is_precise_test_enabled; then
            test_strength="$(get_test_strength $test_group)"
        else
            local wl_dir=$(get_whitelist_conf_dir)
            local whitelist_file="$wl_dir/$(get_whitelist_filename "$test_group")"
            local whitelist_info=$(cat $whitelist_file)
            local all_patch_info_ctx=$(get_patch_info_ctx)

            test_strength=$(get_test_strength_precise "$whitelist_info" "$all_patch_info_ctx")
        fi

        if test $test_strength -gt 1 ; then
            if ! copy_test_cases_strength_times "$test_strength" "$test_group";then
                return $FALSE
            fi
        fi

        printf "[INF] Running full test script '%s' ...\n" "$script_path"
        sh "$script_path" -s $test_strength

        return $TRUE
    fi

    printf "[INF] Running full test script '%s' ...\n" "$script_path"
    sh "$script_path" $sensor_name

    return $TRUE
}

load_test_group()
{
    local i=$1
    local file=$2
    local timeout_str
    local delimiter_cnt

    test_group_list[$i]=$(read_conf_item "group" "$file")
    if is_string_blank "${test_group_list[$i]}"; then
        printf "config item '%s' in config file '%s' is blank\n" "group" "$file"
        return $FALSE
    fi

    test_program_list[$i]=$(read_conf_item "program" "$file")
    if is_string_blank "${test_program_list[$i]}"; then
        printf "config item '%s' in config file '%s' is blank\n" "program" "$file"
        return $FALSE
    fi

    timeout_str=$(read_conf_item "timeout" "$file")
    delimiter_cnt=$(echo "$timeout_str" | grep -o ${CONF_ITEM_DELIMITER} | wc -l)
    #',' delimiter's num must be 2 which is corresponding to
    # timeout="PT_timeout_cfg","ST_timeout_cfg","BT_timeout_cfg"
    if [ $delimiter_cnt -eq 2 ]; then
        if [[ "$cam_test_type" == "snapshot_test" ]]; then
            timeout_str=${timeout_str#*${CONF_ITEM_DELIMITER}}
            timeout_str=${timeout_str%${CONF_ITEM_DELIMITER}*}
        elif [[ "$cam_test_type" == "breadth_test" ]]; then
            timeout_str=${timeout_str##*${CONF_ITEM_DELIMITER}}
        else
            timeout_str=${timeout_str%%${CONF_ITEM_DELIMITER}*}
        fi
    fi
    test_timeout_list[$i]=$timeout_str
    if ! is_number "${test_timeout_list[$i]}"; then
        printf "config item '%s'='%s' in config file '%s' is illegal\n" "timeout" "${test_timeout_list[$i]}" "$file"
        return $FALSE
    fi

    src_data_git_list[$i]=$(read_conf_item "src_data_git" "$file")
    src_data_path_list[$i]=$(read_conf_item "src_data_path" "$file")
    des_data_path_list[$i]=$(read_conf_item "des_data_path" "$file")
    skip_test_when_not_hit_whitelist_list[$i]=0
    skip_test_when_not_hit_whitelist_list[$i]=$(read_conf_item "skip_test_when_not_hit_whitelist" "$file")

    log_file_list[$i]=$(read_conf_item "log_file" "$file")
    gcov_file_list[$i]=$(read_conf_item "gcov_file" "$file")

    printf "[INF] loaded test_group '%s' from file '%s'\n" "${test_group_list[$i]}" "$file"

    return $TRUE
}

load_all_test_group()
{
    printf "[INF] Loading all test_groups ...\n"

    local dir="$(get_test_group_conf_dir)"
    local test_priority
    local i=0
    local prio_nr=0
    local file
    local prio

    for prio in "${test_prio_list[@]}"; do
        local nr${prio}=0
    done

    for file in $dir/test_group_*.conf; do
        if ! test -e $file; then
            continue
        fi

        test_priority=$(read_conf_item "test_priority" "$file")
        if is_string_blank "$test_priority"; then
            test_priority=${test_prio_list[ ${#test_prio_list[@]}-2 ]}
        fi

        if echo "${test_prio_list[@]}" | grep -w "$test_priority" &>/dev/null; then
            eval local file${test_priority}$(eval echo \$nr${test_priority})="$file"
            eval nr${test_priority}=$(eval expr \$nr${test_priority} + 1)
        else
            printf "config item format '%s' in config file '%s' is wrong\n" "test_priority" "$file"
            return $FALSE
        fi
    done

    for prio in "${test_prio_list[@]}"; do
        for prio_nr in $(seq 0 $(eval echo \$nr${prio})); do
            eval file_name=\$file${prio}${prio_nr}
            if [ -z $file_name ]; then
                continue
            fi

            if ! load_test_group $i "$file_name"; then
                return $FALSE
            fi
            i=$(expr $i + 1)
        done
    done

    printf "[INF] %s test_groups loaded...\n" $i

    return $TRUE
}

load_single_test_group()
{
    local test_group=$1
    printf "[INF] Loading test_group:$test_group ...\n"

    local dir="$(get_test_group_conf_dir)"
    local file=$dir/test_group_$test_group.conf

    if ! test -e $file; then
        printf "test group file:$file not exist\n"
        return $FALSE
    fi

    if ! load_test_group 0 "$file"; then
        return $FALSE
    fi

    printf "[INF] test_group:$test_group is loaded...\n"

    return $TRUE
}

is_valid_test_group()
{
    local target_group=$1

    local i
    for i in "${!test_group_list[@]}"
    do
        local test_group=${test_group_list[$i]}
        if test "$test_group" = "$target_group"; then
            return $TRUE
        fi
    done

    return $FALSE
}

get_des_data_path()
{
    local target_group=$1

    local i
    for i in "${!test_group_list[@]}"
    do
        local test_group=${test_group_list[$i]}
        if test "$test_group" = "$target_group"; then
            echo "${des_data_path_list[$i]}"
            return $TRUE
        fi
    done

    return $FALSE
}

detect_input_data_space_usage()
{
    local des_data_path=$1
    local cmd="du -s $des_data_path"
    local output
    if ! output=$(du -s "$des_data_path"); then
        printf "[ERR] '%s' failed with err %s \n" "$cmd" $? >&2
        return $FALSE
    fi

    local word
    for word in $output
    do
        if ! is_number "$word"; then
            printf "[ERR] unexpected output from '%s': '%s'\n" "$cmd" "$output" >&2
            return $FALSE
        else
            echo "$word"
            return $TRUE
        fi
    done
}

is_input_data_ready()
{
    local test_group=$1

    local des_data_path
    if ! des_data_path=$(get_des_data_path $test_group); then
       printf "[ERR] can't get des_data_path for test_group '%s'\n" "$test_group"
       return $FALSE
    fi

    if ! test -d "$des_data_path"; then
        printf "[ERR] des_data_path '%s' for test_group '%s' doesn't exist\n" "$des_data_path" "$test_group"
        return $FALSE
    fi

    local space_usage
    if ! space_usage=$(detect_input_data_space_usage "$des_data_path"); then
        return $FALSE
    fi

    printf "[INF] des_data_path: %s, space_usage: %s, space_usage_previous: %s\n" "$des_data_path" "$space_usage" "$input_data_space_usage"

    if test $space_usage -ne $input_data_space_usage; then
        # input data space usage is changed, clear detecting counter
        input_data_space_usage=$space_usage
        input_data_not_change_counter=0
    else
        # input data space usage isn't changed since last detecting, increase detecting counter
        input_data_not_change_counter=$(expr $input_data_not_change_counter + 1)
        if test $input_data_not_change_counter -ge $INPUT_DATA_NOT_CHANGE_MAX; then
            # input data is ready(input data space usage is not changed for 10 seconds)
            return $TRUE
        fi
    fi

    return $FALSE
}

retry()
{
    local interval=$1
    shift
    local max_retries=$1
    shift
    local cmd="$@"

    local i=0
    while test $max_retries -eq $RETRY_INFINITE -o $i -lt $max_retries
    do
        if $cmd; then
            return $TRUE
        fi

        sleep $interval
        i=$(expr $i + 1)
    done

    return $FALSE
}

wait_for_input_data()
{
    local test_group=$1

    input_data_space_usage=-1
    input_data_not_change_counter=0

    printf "[INF] %s: waiting for input data...\n" "$test_group"

    if ! retry $RETRY_INTERVAL $RETRY_INFINITE is_input_data_ready $test_group; then
        printf "[ERR] %s: waiting for input data timeout\n" "$test_group" >&2
        return $FALSE
    else
        printf "[INF] %s: input data is ready, input data size: %s * 1024 bytes\n" "$test_group" $input_data_space_usage
        return $TRUE
    fi
}

is_skip_test_when_not_hit_whitelist_list()
{
    local target_group=$1

    local i
    for i in "${!test_group_list[@]}"
    do
        local test_group=${test_group_list[$i]}
        if test "$test_group" = "$target_group"; then
            if test "${skip_test_when_not_hit_whitelist_list[$i]}" = "true"; then
                return $TRUE
            fi
            return $FALSE
        fi
    done

    return $FALSE
}

run_single_test()
{
    local test_group=$1

    if is_test_need_input_data $test_group; then
        if ! is_whitelist_enabled; then
            printf "[INF] test_group '%s' needs input data, ignored\n" "$test_group"
            return $TRUE
        fi

        if ! wait_for_input_data $test_group; then
            return $FALSE
        fi
    fi

    run_full_test $test_group
}

run_all_test()
{
    local i
    local test_group

    if ! parse_git_project_list "$git_project_str" $CONF_ITEM_DELIMITER; then
        return $FALSE
    fi

    if test -e "$(get_precise_test_conf_path)"; then
        if  ! prepare_precise_test "$(get_patch_info_dir)"; then
            return $FALSE
        fi
    fi

    if is_precise_test_enabled; then
        local all_patch_info_ctx=$(get_patch_info_ctx)
        local wl_dir=$(get_whitelist_conf_dir)
        local whitelist_file
        local file_ctx

        for i in "${!test_group_list[@]}"
        do
            test_group=${test_group_list[$i]}
            whitelist_file="$wl_dir/$(get_whitelist_filename "$test_group")"
            file_ctx=$(cat $whitelist_file)

            eval whitelist_ctx${test_group}=$(echo \$file_ctx)
        done

        for i in "${!test_group_list[@]}"
        do
            test_group=${test_group_list[$i]}

            eval whitelist_info=\$whitelist_ctx${test_group}
            if ! is_patch_info_hit_precise "$whitelist_info" "$all_patch_info_ctx" "$test_group"; then
                continue
            fi
            run_single_test "$test_group"
        done
    else
        for i in "${!test_group_list[@]}"
        do
            test_group=${test_group_list[$i]}

            if is_whitelist_enabled; then
                if ! is_whitelist_hit "$test_group"; then
                    continue
                fi
            fi
            run_single_test "$test_group"
        done
    fi
}

run_test_group()
{
    local test_group=$1

    if ! is_whitelist_enabled; then
        printf "%s: git project list missing while running test_group '%s'\n" $0 "$test_group" >&2
        return $FALSE
    fi

    if ! is_valid_test_group "$test_group"; then
        printf "%s: error: '%s' is not a valid test_group\n" $0 "$test_group" >&2
        return $FALSE
    fi

    if run_single_test "$test_group"; then
        return $TRUE
    else
        return $FALSE
    fi
}

main()
{
    local cmd_line="$@"
    if ! parse_cmd_line $cmd_line; then
        printf "%s: failed to parse command line: %s\n" $0 "$cmd_line" >&2
        show_usage
        exit $FALSE
    fi

    if test "$query_cmd"; then
        if ! load_all_test_group; then
            return $FALSE
        fi

        if ! parse_git_project_list "$git_project_str" $CONF_ITEM_DELIMITER; then
            return $FALSE
        fi

        if test -e "$(get_precise_test_conf_path)"; then
            if  ! prepare_precise_test "$(get_patch_info_dir)"; then
                return $FALSE
            fi
        fi
        # -q test_seq
        if ! is_precise_test_enabled; then
            if result=$(query_test_seq); then
                printf "$result\n"
                exit $TRUE
            else
                exit $FALSE
            fi
        else
            if result=$(query_precise_test_seq); then
                printf "$result\n"
                exit $TRUE
            else
                exit $FALSE
            fi
        fi
    elif test "$test_group_to_be_run"; then
        if ! load_single_test_group $test_group_to_be_run; then
            exit $FALSE
        fi

        if [[ "$cam_test_type" == "snapshot_test" ]]; then
            export CAM_TEST_ENV="snapshot_test"
        elif [[ "$cam_test_type" == "breadth_test" ]]; then
            export CAM_TEST_ENV="breadth_test"
        else
            export CAM_TEST_ENV="patch_test"
        fi

        # -p <...> -g <test_group>
        if run_test_group "$test_group_to_be_run"; then
            exit $TRUE
        else
            exit $FALSE
        fi
    else
        if ! load_all_test_group; then
            return $FALSE
        fi
        run_all_test
    fi
}

main "$@"
