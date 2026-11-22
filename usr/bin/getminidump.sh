#! /bin/sh

## transfer mini dump from ramdump area
## we estimate mini dump not bigger than 200Mb 

checkfile="/blackbox/system/minidump/checkdump"      ##make sure this file size is bigger than 30
partition="/dev/disk/by-partlabel/rawdump"
dump_dir="/blackbox/system/minidump/storage/"

check_mini_dump_exist() { 
    checkwords="we estimate mini dump not bigger than 200Mb "
    dump_type_file="/sys/kernel/dload/dload_mode"

    if [ ! -e "$partition" ]; then  ## no rawdump partition, exit
        exit 0
    fi

    if [ ! -e "$checkfile" ] || [ "$(wc -c < $checkfile)" -lt 30 ]; then  ## create check file in first boot, no checkfile, no dump
        touch "${checkfile}"
        echo "${checkwords}" > "${checkfile}"
        dd if="${checkfile}"  of="${partition}"    ##init the dump partition
        exit 0
    fi

    if [ ! grep -q "\<mini\>" "${dump_type_file}" ]; then   ## just transfer mini dump
        echo "just mini dump need transfer here"
        exit 0
    fi

    checkfile30=$(head -c 30 "${checkfile}")
    partition30=$(head -c 30 "${partition}")
    diff30=$(diff <(echo "$checkfile30") <(echo "$partition30"))
    if [ -z "$diff30" ]; then    ##compare partition words and checkfile words, if the same, no crash hanppend
        exit 0
    fi
}

get_dump_data_and_tarz() {
    current_time=$(date +"%Y%m%d%H%M%S")
    file_name="minidump"
    file_extension=".tar.gz"
	dump_create_dir="${file_name}_${current_time}/"
	new_target_dir="${dump_dir}${file_name}_${current_time}"
    new_file_name="${dump_dir}${file_name}_${current_time}${file_extension}"

	mkdir -p "${new_target_dir}"
	python  /usr/bin/minidump.py -s "${partition}" "${new_target_dir}"
	python  /usr/bin/kpanic_console.py ${new_target_dir} /blackbox/system/kpanic_console
	tar -czvf "${new_file_name}" -C "${dump_dir}" "${dump_create_dir}"
    dd if="${checkfile}"  of="${partition}"   ##write the check words to partition, for next time check minidump status
	if [ -e "$new_target_dir" ]; then
	    rm -r "${new_target_dir}"
	fi
}

keep_cuctomize_num_dumps()
{
    cd "${dump_dir}"
    file_count=$(ls -1 | wc -l)
    if [ $file_count -gt 8 ]; then
        files_to_delete=$((file_count - 8))
        ls -1t | tail -n $files_to_delete | xargs rm
    fi
}

minidump_main() {
    if [ ! -d "${dump_dir}" ]; then
        mkdir -p "${dump_dir}"
    fi

    check_mini_dump_exist
    get_dump_data_and_tarz
    keep_cuctomize_num_dumps
}

minidump_main
