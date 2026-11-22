#! /bin/bash

readonly dir="$(cd $(dirname $0) && pwd)"
readonly TRUE=0
readonly FALSE=1

#precise_test related file path
readonly test_group_conf_path="/system/etc"
readonly test_script_path="/system/bin"
readonly patch_info_path="/system/etc/patch_info"
readonly precise_test_enable_file_name="cam_precise_test.conf"
readonly precise_test_enable_file_path="/system/etc"

#precise_test_unit(ptu) configuration file path
readonly ptu_enable_file_conf_path="system/etc/precise_test_unit/enable_file_conf"
readonly ptu_patch_info_conf_path="system/etc/precise_test_unit/patch_info_conf"
readonly ptu_whitelist_conf_path="system/etc/precise_test_unit/whitelist_conf"
readonly ptu_backup_path="/system/etc/ptu_backup"

ptu_whitelist_conf_load_path=""
ptu_patch_info_conf_load_path=""
ptu_enable_file_conf_load_path=""

test_case_list=(
"$dir/test_dji_camera_entrance.sh"
"$dir/test_dji_camera_entrance.sh -p"
"$dir/test_dji_camera_entrance.sh -q"
"$dir/test_dji_camera_entrance.sh -g"
"$dir/test_dji_camera_entrance.sh -x"
"$dir/test_dji_camera_entrance.sh -p -q"
"$dir/test_dji_camera_entrance.sh -g -p"
"$dir/test_dji_camera_entrance.sh -q test_seq"
"$dir/test_dji_camera_entrance.sh -g unknow_group"
"$dir/test_dji_camera_entrance.sh -g cht"
"$dir/test_dji_camera_entrance.sh -p common/dcam_frwk -q"
"$dir/test_dji_camera_entrance.sh -p dcamgit:common/dcam_frwk -q"
"$dir/test_dji_camera_entrance.sh -p dcamgit:common/dcam_frwk -q unknown_query"
"$dir/test_dji_camera_entrance.sh -p dcamgit:common/dcam_frwk -q test_seq"
"$dir/test_dji_camera_entrance.sh -p dcamgit:common/dcam_frwk"
"$dir/test_dji_camera_entrance.sh -p dcamgit:common/dcam_frwk,"
"$dir/test_dji_camera_entrance.sh -p dcamgit:common/dcam_frwk -g cht"
"$dir/test_dji_camera_entrance.sh -p dcamgit:common/dcam_frwk -g cst"
"$dir/test_dji_camera_entrance.sh -p dcamgit:common/dcam_frwk -g pbt"
"$dir/test_dji_camera_entrance.sh -p dcamgit:common/dcam_frwk -g ppt"
"$dir/test_dji_camera_entrance.sh -p dcamgit:common/dcam_frwk,dcamgit:service/rcam_user -q test_seq"
"$dir/test_dji_camera_entrance.sh -p dcamgit:common/dcam_frwk,dcamgit:service/rcam_user"
"$dir/test_dji_camera_entrance.sh -p dcamgit:service/rcam_user -q test_seq"
"$dir/test_dji_camera_entrance.sh -p dcamgit:service/rcam_user"
"$dir/test_dji_camera_entrance.sh -p dcamgit:service/rcam_user -g cht"
"$dir/test_dji_camera_entrance.sh -p dcamgit:service/rcam_user -g cst"
"$dir/test_dji_camera_entrance.sh -p dcamgit:service/rcam_user -g pbt"
"$dir/test_dji_camera_entrance.sh -p dcamgit:service/rcam_user -g ppt"
"$dir/test_dji_camera_entrance.sh -p all -q test_seq"
"$dir/test_dji_camera_entrance.sh -p all"
"$dir/test_dji_camera_entrance.sh -p all -g cht"
"$dir/test_dji_camera_entrance.sh -p all -g cst"
"$dir/test_dji_camera_entrance.sh -p all -g pbt"
"$dir/test_dji_camera_entrance.sh -p all -g ppt"
"$dir/test_dji_camera_entrance.sh -p snapshot_test"
)

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

copy_sepc_file()
{
    local src_path=$1
    local dest_path=$2
    local spec_str=$3

    if ! test -d "$src_path"; then
        echo "no path:$src_path"
    fi

    if ! test -d "$dest_path"; then
        mkdir $dest_path
    fi
    for file in $src_path/$spec_str; do
        if test -f $file; then
            cp $file $dest_path
        fi
    done
}

moving_sepc_file()
{
    local src_path=$1
    local dest_path=$2
    local spec_str=$3

    if ! test -d "$src_path"; then
        echo "no path:$src_path"
        return
    fi

    if ! test -d "$dest_path"; then
        mkdir $dest_path
    fi

    for file in $src_path/$spec_str; do
        if test -f $file; then
            mv $file $dest_path
        fi
    done
}

removing_sepc_file()
{
    local path=$1
    local related_str=$2

    for file in $path/$related_str; do
        if test -f $file; then
            rm $file
        fi
    done
}

precise_test_unit_load_enable_file_conf()
{
    local enable_ft=$1

    case "$enable_ft" in
        "enable_ft_not_exist")
            ;;
        "enable_ft_normal_enable")
            ptu_enable_file_conf_load_path="normal_enable"
            ;;
        "enable_ft_error_file_name")
            ptu_enable_file_conf_load_path="error_file_name"
            ;;
        *)
            echo "[ERR] Error load_enable_file_conf($enable_ft), please check test_case conf!"
            return $FALSE
            ;;
    esac

    if ! is_string_blank $ptu_enable_file_conf_load_path; then
        copy_sepc_file $ptu_enable_file_conf_path/$ptu_enable_file_conf_load_path  $precise_test_enable_file_path "*"
    fi

    return $TRUE
}

precise_test_unit_load_whitelist_file_conf()
{
    local whitelist_ft=$1

    case "$whitelist_ft" in
        "whitelist_ft_no_whitelist_file")
            ;;
        "whitelist_ft_non_precise_test")
            ptu_whitelist_conf_load_path="non_precise_test"
            ;;
        "whitelist_ft_precise_test_normal")
            ptu_whitelist_conf_load_path="precise_test_normal"
            ;;
        "whitelist_ft_precise_test_without_quick_script")
            removing_sepc_file $test_script_path "test_dji_*_quick.sh"
            ptu_whitelist_conf_load_path="precise_test_without_quick_script"
            ;;
        "whitelist_ft_prec_test_wl_empty_with_quick_script")
            ptu_whitelist_conf_load_path="prec_test_wl_empty_with_quick_script"
            ;;
        "whitelist_ft_prec_test_wl_empty_without_quick_script")
            removing_sepc_file $test_script_path "test_dji_*_quick.sh"
            ptu_whitelist_conf_load_path="prec_test_wl_empty_without_quick_script"
            ;;
        "whitelist_ft_precise_test_normal_with_test_strength")
            ptu_whitelist_conf_load_path="precise_test_normal_with_test_strength"
            ;;
        *)
            echo "[ERR] Error load_whitelist_file_conf($whitelist_ft), please check test_case_list"
            return $FALSE
            ;;
    esac

    if ! is_string_blank $ptu_whitelist_conf_load_path; then
        copy_sepc_file $ptu_whitelist_conf_path/$ptu_whitelist_conf_load_path  $test_group_conf_path "whitelist*"
        copy_sepc_file $ptu_whitelist_conf_path/$ptu_whitelist_conf_load_path  $test_group_conf_path "test_group*"
        copy_sepc_file $ptu_whitelist_conf_path/$ptu_whitelist_conf_load_path  $test_group_conf_path "*cases.conf"
        copy_sepc_file $ptu_whitelist_conf_path/$ptu_whitelist_conf_load_path  $test_script_path "*.sh"
    fi

    return $TRUE
}

precise_test_unit_load_patch_info_conf()
{
    local patch_info_type=$1

    case "$patch_info_type" in
        "patch_info_type_path_not_exist")
            rm -rf $patch_info_path
            ;;
        "patch_info_type_empty_path")
            ;;
        "patch_info_type_empty_file")
            ptu_patch_info_conf_load_path="empty_file"
            ;;
        "patch_info_type_exceed_num_threshold")
            ptu_patch_info_conf_load_path="exceed_num_threshold"
            ;;
        "patch_info_type_precise_test_with_mapping")
            ptu_patch_info_conf_load_path="precise_test_with_mapping"
            ;;
        "patch_info_type_precise_test_without_mapping")
            ptu_patch_info_conf_load_path="precise_test_without_mapping"
            ;;
        *)
            echo "[ERR] Error load_patch_info_conf($patch_info_type), please check test_case_list!"
            return $FALSE
            ;;
    esac

    if ! is_string_blank $ptu_patch_info_conf_load_path; then
        copy_sepc_file $ptu_patch_info_conf_path/$ptu_patch_info_conf_load_path  $patch_info_path "*"
    fi

    return $TRUE
}

run_precise_test_unit()
{
    local test_type=$1
    local enable_file_conf=$2
    local whitelist_file_conf=$3
    local patch_info_file_conf=$4
    local run_cmd=""
    local is_strength_enable=$FALSE

    #load file configuration
    ptu_enable_file_conf_load_path=""
    ptu_whitelist_conf_load_path=""
    ptu_patch_info_conf_load_path=""
    if ! is_string_blank $enable_file_conf; then
        if ! precise_test_unit_load_enable_file_conf $(trim_space "$enable_file_conf"); then
            return $FALSE
        fi
    fi
    if ! is_string_blank $whitelist_file_conf; then
        if ! precise_test_unit_load_whitelist_file_conf $(trim_space "$whitelist_file_conf"); then
            return $FALSE
        fi
    fi
    if ! is_string_blank $patch_info_file_conf; then
        if ! precise_test_unit_load_patch_info_conf $(trim_space "$patch_info_file_conf"); then
            return $FALSE
        fi
    fi

    #doing test base on test_type
    if [[ $test_type == *"strength" ]]; then
        test_type=${test_type%%"_strength"*}
        is_strength_enable=$TRUE
    fi

    case "$test_type" in
        "test_type_get_seq")
            run_cmd="$dir/test_dji_camera_entrance.sh -p dcamgit:common/dcam_base -q test_seq"
            ;;
        "test_type_run_all")
            run_cmd="$dir/test_dji_camera_entrance.sh -p snapshot_test"
            ;;
        "test_type_single_run"*)
            local single_test_group=${test_type#*"test_type_single_run_"}
            run_cmd="$dir/test_dji_camera_entrance.sh -p dcamgit:common/dcam_base -g $single_test_group"
            ;;
        "test_type_snapshot_test_single_run"*)
            local single_test_group=${test_type#*"test_type_snapshot_test_single_run_"}
            run_cmd="$dir/test_dji_camera_entrance.sh -p snapshot_test -g $single_test_group"
            ;;
        *)
            echo "[ERR] Error tese type conf($test_type), please check test_case_list!"
            return $FALSE
            ;;
    esac

    if test $is_strength_enable; then
        run_cmd="$run_cmd -r"
    fi

    $run_cmd

    return $TRUE
}

clean_test_case_conf()
{
    local file_base_name
    local file

    if ! is_string_blank $ptu_enable_file_conf_load_path; then
        for file in $ptu_enable_file_conf_path/$ptu_enable_file_conf_load_path/*; do
            file_base_name=$(basename -- "$file")
            removing_sepc_file $precise_test_enable_file_path "$file_base_name"
        done
    fi

    if ! is_string_blank $ptu_whitelist_conf_load_path; then
        for file in $ptu_whitelist_conf_path/$ptu_whitelist_conf_load_path/*;
        do
            file_base_name=$(basename -- "$file")
            if [[ "$file_base_name" == "test_dji"* ]]; then
                removing_sepc_file $test_script_path "$file_base_name"
            else
                removing_sepc_file $test_group_conf_path "$file_base_name"
            fi
        done
    fi

    if ! is_string_blank $ptu_patch_info_conf_load_path; then
        for file in $ptu_patch_info_conf_path/$ptu_patch_info_conf_load_path/*; do
            file_base_name=$(basename -- "$file")
            removing_sepc_file $patch_info_path "$file_base_name"
        done
    fi
}

# precise_test_unit_list_conf_instruction:
#    test_type            precise_test_enable_file_type            whitelist_conf_file_type            patch_info_conf_file            | expect_result: precise_qurey/precise_test or not, qurey_output/about_to_run test_group
precise_test_case_list=(
    #check precise_test enable file
    "test_type_get_seq,    enable_ft_not_exist,        whitelist_ft_non_precise_test                                                    | rlt_exp: non_precise_qurey, cap_cht&cap_cst"
    "test_type_get_seq,    enable_ft_error_file_name,  whitelist_ft_precise_test_normal,   patch_info_type_precise_test_without_mapping | rlt_exp: non_precise_qurey, cap_cht&cap_cst"

    #precise mapping check
    "test_type_get_seq,    enable_ft_normal_enable,    whitelist_ft_precise_test_normal,   patch_info_type_path_not_exist               | rlt_exp: non_precise_qurey, cap_cht&cap_cst"
    "test_type_get_seq,    enable_ft_normal_enable,    whitelist_ft_precise_test_normal,   patch_info_type_empty_file                   | rlt_exp: non_precise_qurey, cap_cht&cap_cst"
    "test_type_get_seq,    enable_ft_normal_enable,    whitelist_ft_precise_test_normal,   patch_info_type_empty_path                   | rlt_exp: non_precise_qurey, cap_cht&cap_cst"
    "test_type_get_seq,    enable_ft_normal_enable,    whitelist_ft_precise_test_normal,   patch_info_type_exceed_num_threshold         | rlt_exp: non_precise_qurey, cap_cht&cap_cst"
    "test_type_get_seq,    enable_ft_normal_enable,    whitelist_ft_precise_test_normal,   patch_info_type_precise_test_with_mapping                     | rlt_exp: precise_qurey, cap_cht&cap_cst"
    "test_type_get_seq,    enable_ft_normal_enable,    whitelist_ft_precise_test_normal,   patch_info_type_precise_test_without_mapping                  | rlt_exp: precise_qurey, quick cap_cst"
    "test_type_get_seq,    enable_ft_normal_enable,    whitelist_ft_precise_test_without_quick_script,    patch_info_type_precise_test_without_mapping   | rlt_exp: precise_qurey no test_group"
    "test_type_get_seq,    enable_ft_normal_enable,    whitelist_ft_non_precise_test,      patch_info_type_precise_test_with_mapping                     | rlt_exp: precise_qurey, cap_cht&cap_cst"

    #run all test
    "test_type_run_all,    enable_ft_normal_enable,    whitelist_ft_precise_test_normal,   patch_info_type_precise_test_with_mapping    | rlt_exp: non_precise_test, run cap_cht&cap_cst"

    ##test strength
    "test_type_get_seq_strength,    enable_ft_normal_enable,     whitelist_ft_precise_test_normal_with_test_strength,    patch_info_type_precise_test_with_mapping              | rlt_exp: precise_qurey cap_cht timeout x3"
    "test_type_single_run_cap_cht_strength,     enable_ft_normal_enable,     whitelist_ft_precise_test_normal_with_test_strength,    patch_info_type_precise_test_with_mapping  | rlt_exp: precise_test run cap_cht x3"

    #check empty whitelist file
    "test_type_get_seq,    enable_ft_normal_enable,    whitelist_ft_prec_test_wl_empty_with_quick_script,       patch_info_type_precise_test_with_mapping    | rlt_exp: precise_qurey, quick cap_cst"
    "test_type_get_seq,    enable_ft_normal_enable,    whitelist_ft_prec_test_wl_empty_without_quick_script,    patch_info_type_precise_test_with_mapping    | rlt_exp: precise_qurey, no test_group"

    #single test group run check (patch_test)
    "test_type_single_run_cap_cst,    enable_ft_normal_enable,    whitelist_ft_precise_test_normal,    patch_info_type_empty_file                   | rlt_exp: non_precise_test, run cap_cst"
    "test_type_single_run_cap_cst,    enable_ft_normal_enable,    whitelist_ft_precise_test_normal,    patch_info_type_precise_test_with_mapping    | rlt_exp: precise_test, run cap_cst"
    "test_type_single_run_cap_cst,    enable_ft_normal_enable,    whitelist_ft_precise_test_normal,    patch_info_type_precise_test_without_mapping | rlt_exp: precise_test, run quick cap_cst"

    #single test group run check (snapshot_test)
    "test_type_snapshot_test_single_run_cap_cst,    enable_ft_normal_enable,    whitelist_ft_precise_test_normal,    patch_info_type_empty_file                     | rlt_exp: non_precise_test, run cap_cst"
    "test_type_snapshot_test_single_run_cap_cst,    enable_ft_normal_enable,    whitelist_ft_precise_test_normal,    patch_info_type_precise_test_with_mapping      | rlt_exp: non_precise_test, run cap_cst"
    "test_type_snapshot_test_single_run_cap_cst,    enable_ft_normal_enable,    whitelist_ft_precise_test_normal,    patch_info_type_precise_test_without_mapping   | rlt_exp: non_precise_test, run cap_cst"
)

main()
{
    local precise_test_case
    local rlt_exp

    for i in "${!test_case_list[@]}"
    do
        local test_case=${test_case_list[$i]}
        echo "================================================================================"
        echo $test_case
        echo "--------------------------------------------------------------------------------"
        eval $test_case
        echo
    done

    #move all exist test_info to other file for doing precise test unit
    moving_sepc_file $test_group_conf_path $ptu_backup_path $precise_test_enable_file_name
    moving_sepc_file $test_group_conf_path $ptu_backup_path "test_group*"
    moving_sepc_file $test_group_conf_path $ptu_backup_path "whitelist*"
    moving_sepc_file $test_group_conf_path $ptu_backup_path "*cases.conf"
    moving_sepc_file $patch_info_path $ptu_backup_path/"patch_info_bak" "*"
    copy_sepc_file $test_script_path $ptu_backup_path "test_dji_*"

    old_ifs=$IFS
    IFS=$' ,\n'
    for i in "${!precise_test_case_list[@]}"
    do
        precise_test_case=${precise_test_case_list[$i]%\|*}
        rlt_exp=${precise_test_case_list[$i]#*\|}
        echo "================================================================================"
        echo $precise_test_case
        echo "--------------------------------------------------------------------------------"
        #$precise_test_case run
        if ! run_precise_test_unit $precise_test_case; then
            echo "[ERR] test_script running fail!"
            break
        fi
        #clean case_file_conf
        clean_test_case_conf
        echo "================[INF] case run over, please check output,$rlt_exp================="
        echo
    done

    #recover whitelist file
    moving_sepc_file $ptu_backup_path $test_group_conf_path $precise_test_enable_file_name
    moving_sepc_file $ptu_backup_path $test_group_conf_path "test_group*"
    moving_sepc_file $ptu_backup_path $test_group_conf_path "whitelist*"
    moving_sepc_file $ptu_backup_path $test_group_conf_path "*cases.conf"
    moving_sepc_file $ptu_backup_path/"patch_info_bak" $patch_info_path "*"
    moving_sepc_file $ptu_backup_path $test_script_path "test_dji_*"
    IFS=old_ifs
}

main "$@"
