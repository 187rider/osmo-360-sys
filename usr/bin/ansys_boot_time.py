import re
import sys
import os
import time
import subprocess

# global variable 
kmsg_name = "/blackbox/system/kmsg.log"
svg_name  = "/tmp/systemd.svg"
uefi_name = "/blackbox/system/uefi_0.log"

# common function
def get_start_val_from_svg(line):
    match = re.search(r'x="(\d+\.\d+)"', line)
    if match:
        return int(float(match.group(1))*10-50)
    return 0

def get_use_val_from_svg(line):
    match = re.search(r'\((\d+\.\d+)s\)', line)
    if match:
        return int(float(match.group(1))*1000)
    match = re.search(r'\((\d+)ms\)', line)
    if match:
        return int(float(match.group(1)))
    return 0

def get_end_val_from_svg(line):
    start = get_start_val_from_svg(line)
    use = get_use_val_from_svg(line)
    return start + use

def get_linux_time_from_line(line):
    pattern = r".*\[\s*(\d+.\d+)\].*"
    obj = re.match(pattern, line)
    if obj:
        return float(obj.group(1))
    return 0.0

def get_linux_time_from_flie(key_word, file_name):
    line = find_line_from_file(key_word, file_name)
    if line == "":
        return 0

    a = get_linux_time_from_line(line)
    return int(a*1000)

def file_readlines(file_name):
    return open(file_name, 'r', errors='ignore').readlines()

def find_line_from_file(key_words, file_name):
    lines = open(file_name, 'r', errors='ignore').readlines()
    for line in lines:
        if key_words in line:
            return line
    return ""

# find log from uefi
# APBL start: 345
def get_pbl_start_time():
    kw = "Kernel MPM timestamp"
    fn = uefi_name
    line = find_line_from_file(kw, fn)
    if line == "":
        return 0
    match = re.search(r'APBL Exit: (\d+)', line)
    if match:
        return int(int(match.group(1))/1000)
    return 0

# B -    153720 - SBL1, Start
def get_sbl_start_time():
    kw = "SBL1, Start"
    fn = uefi_name
    line = find_line_from_file(kw, fn)
    if line == "":
        return 0
    match = re.search(r'(\d+)', line)
    if match:
        return int(int(match.group(1))/1000)
    return 0

# UEFI Start     [ 1401]
def get_xbl_start_time():
    kw = "UEFI Start"
    fn = uefi_name
    line = find_line_from_file(kw, fn)
    if line == "":
        return 0
    match = re.search(r'(\d+)', line)
    if match:
        return int(match.group(1))
    return 0

# POST Time      [ 1925] OS Loader
def get_abl_start_time():
    kw = "OS Loader"
    fn = uefi_name
    line = find_line_from_file(kw, fn)
    if line == "":
        return 0
    match = re.search(r'(\d+)', line)
    if match:
        return int(match.group(1))
    return 0

# find log from kmsg
# <6>[    3.058647][  T405] KPI: Kernel MPM timestamp = 193895
def get_bootloader_time():
    kw = "Kernel MPM timestamp"
    fn = kmsg_name
    line = find_line_from_file(kw, fn)
    if line == "":
        return 0

    a = get_linux_time_from_line(line)
    b = 0
    b_match = re.search(r'timestamp = (\d+)', line)
    if b_match:
        b = int(b_match.group(1))
    return int((b / 32768 - a) * 1000)

# <11>[    4.709060][ T1182] CameraService [bootup]Camera Service for Seal is starting...: sys_counter(0), Tue Mar 26 11:32:14 2024
def get_dji_camera3_main_time():
    kw = "Camera Service for Seal is starting"
    fn = kmsg_name
    return get_linux_time_from_flie(kw, fn)

# <12>[    7.228196][ T2717] INFO: Camera liveview first frame is ready for display
def get_liveview_time():
    kw = "liveview first frame is ready"
    fn = kmsg_name
    return get_linux_time_from_flie(kw, fn)

# <12>[    0.772266][  T369] Switching to composition number 0x901D
def get_usb1_time():
    kw = "Switching to composition number 0x901D"
    fn = kmsg_name
    return get_linux_time_from_flie(kw, fn)

# <12>[    3.347420][ T1831] Switching to composition number 0x8007 bulk
def get_usb2_time():
    kw = "Switching to composition number 0x8007 bulk"
    fn = kmsg_name
    return get_linux_time_from_flie(kw, fn)

# find log from svg
def get_kernel_time():
    kw = "initrd</text>"
    fn = svg_name
    line = find_line_from_file(kw, fn)
    if line == "":
        return 0

    return get_start_val_from_svg(line)

def get_init_start_time():
    kw = "init-log: init started!"
    fn = kmsg_name
    return get_linux_time_from_flie(kw, fn)

def get_chroot_end_time():
    kw = "chroot finished!"
    fn = kmsg_name
    return get_linux_time_from_flie(kw, fn)

def get_mount_others_time():
    kw = "mount_others end"
    fn = kmsg_name
    return get_linux_time_from_flie(kw, fn)

def get_second_stage_ko_time():
    kw = "start_dji_system_2 end"
    fn = kmsg_name
    return get_linux_time_from_flie(kw, fn)

def get_initrd_time():
    kw = "initrd-switch-root.service"
    fn = svg_name
    line = find_line_from_file(kw, fn)
    if line == "":
        return 0

    return get_start_val_from_svg(line)

def get_switch_root_time():
    kw = "systemd-modules-load.service"
    fn = svg_name
    line = find_line_from_file(kw, fn)
    if line == "":
        return 0

    return get_start_val_from_svg(line)

def get_systemd_modules_load_time():
    kw = "systemd-modules-load.service"
    fn = svg_name
    line = find_line_from_file(kw, fn)
    if line == "":
        return 0

    return get_end_val_from_svg(line)

def get_start_dji_camera3_time():
    kw = "dji_camera3.service"
    fn = svg_name
    line = find_line_from_file(kw, fn)
    if line == "":
        return 0

    return get_start_val_from_svg(line)

def get_aosp_start_dji_camera3_time():
    kw = "Command 'start dji_camera3'"
    fn = kmsg_name
    return get_linux_time_from_flie(kw, fn)

# time dump
def time_dump(time_list, name_list, debug=0):
    print(time_list)
    if debug==0:
        return

    sf = "{:<25s}: {:>7s}s ({:>5}s)"

    if len(time_list) != len(name_list):
        print("two list len is not equal!")
        return

    time_d_list = [time_list[0]]
    for i in range(len(time_list)-1):
        time_d_list.append(time_list[i+1]-time_list[i])

    t = [round(float(item)/1000,3) for item in time_list]
    t_str = ["{:.3f}".format(item) for item in t]

    td = [round(float(item)/1000,3) for item in time_d_list]
    td_str = ["{:.3f}".format(item) for item in td]

    for i in range(len(time_list)):
        print(sf.format(name_list[i], t_str[i], td_str[i]))

# API: camera3
# [         bootloader_end,
#               kernel_end,
#               initrd_end,
#          switch_root_end,
# systemd_modules_load_end,
#        start_dji_camera3,
#         dji_camera3_main,
#                 liveview]
def __ansys_camera3_time():
    bootloader = get_bootloader_time()
    dji_camera3_main = get_dji_camera3_main_time()
    liveview = get_liveview_time()

    kernel = get_kernel_time()
    initrd = get_initrd_time()
    switch_root = get_switch_root_time()
    systemd_modules_load = get_systemd_modules_load_time()
    start_dji_camera3 = get_start_dji_camera3_time()

    a = [0, kernel, initrd, switch_root, systemd_modules_load, start_dji_camera3, dji_camera3_main, liveview]
    time_list = [int(i+bootloader) for i in a]
    name_list = ["bootloader_end", "kernel_end", "initrd_end", "switch_root_end",
"systemd_modules_load_end", "start_dji_camera3", "dji_camera3_main", "liveview"]
    return time_list, name_list

def ansys_camera3_time(debug=0):
    time_list,name_list = __ansys_camera3_time()
    time_dump(time_list, name_list, debug)

# API: bootloader
def __ansys_bootloader_time(debug=0):
    sbl_end = get_xbl_start_time()
    xbl_end = get_abl_start_time()
    abl_end = get_bootloader_time()
    bootloader = get_bootloader_time()

    a = [sbl_end, xbl_end, abl_end, bootloader]
    time_list = [int(i) for i in a]
    name_list = ["sbl_end", "xbl_end", "abl_end", "bootloader_end"]
    return time_list, name_list

def ansys_bootloader_time(debug=0):
    time_list,name_list = __ansys_bootloader_time()
    time_dump(time_list, name_list, debug)

# API: usb
# [  bootloader_end,
#        usb 0x901D,
#        usb 0x8007]
def __ansys_usb_time():
    bootloader = get_bootloader_time()
    usb1 = get_usb1_time()
    usb2 = get_usb2_time()

    a = [0, usb1, usb2]
    time_list = [int(i+bootloader) for i in a]
    name_list = ["bootloader_end", "usb 0x901D", "usb 0x8007"]
    return time_list, name_list

def ansys_usb_time(debug=0):
    time_list,name_list = __ansys_usb_time()
    time_dump(time_list, name_list, debug)

# API: all
def __ansys_all_time():
    time_list,name_list   = __ansys_bootloader_time()
    time_list2,name_list2 = __ansys_camera3_time()
    return time_list[:-1]+time_list2, name_list[:-1]+name_list2

def ansys_all_time(debug=0):
    time_list,name_list  = __ansys_all_time()
    time_dump(time_list, name_list, debug)

# API: sat
# [         bootloader_end,
#               kernel_end,
#               usb 0x901D,
#               initrd_end,
#          switch_root_end,
# systemd_modules_load_end,
#        start_dji_camera3,
#         dji_camera3_main,
#               usb 0x8007,
#                 liveview]
def __ansys_sat_time():
    bootloader = get_bootloader_time()
    # bootloader = 2650
    usb1 = get_usb1_time()
    usb2 = get_usb2_time()
    dji_camera3_main = get_dji_camera3_main_time()
    liveview = get_liveview_time()

    kernel = get_kernel_time()
    initrd = get_initrd_time()
    switch_root = get_switch_root_time()
    systemd_modules_load = get_systemd_modules_load_time()
    start_dji_camera3 = get_start_dji_camera3_time()

    a = [0, kernel, usb1, initrd, switch_root, systemd_modules_load, start_dji_camera3, dji_camera3_main, usb2, liveview]
    time_list = [int(i+bootloader) for i in a]
    name_list = ["bootloader_end", "kernel_end", "usb 0x901D", "initrd_end", "switch_root_end",
"systemd_modules_load_end", "start_dji_camera3", "dji_camera3_main", "usb 0x8007", "liveview"]
    return time_list, name_list

# API: aosp_init
# [         bootloader_end,
#               init_start,
#               usb 0x901D,
#               chroot_end,
#             mount_others,
#          second_stage_ko,
#        start_dji_camera3,
#         dji_camera3_main,
#               usb 0x8007,
#                 liveview]
def __ansys_aosp_init_time():
    bootloader = get_bootloader_time()
    # bootloader = 2650
    usb1 = get_usb1_time()
    usb2 = get_usb2_time()
    dji_camera3_main = get_dji_camera3_main_time()
    liveview = get_liveview_time()

    init_start = get_init_start_time()
    chroot_end = get_chroot_end_time()
    mount_others = get_mount_others_time()
    second_stage_ko = get_second_stage_ko_time()
    start_dji_camera3 = get_aosp_start_dji_camera3_time()

    a = [0, init_start, usb1, chroot_end, mount_others, second_stage_ko, start_dji_camera3, dji_camera3_main, usb2, liveview]
    time_list = [int(i+bootloader) for i in a]
    name_list = ["bootloader_end", "init_start", "usb 0x901D", "chroot_end", "mount_others", "second_stage_ko",
"start_dji_camera3", "dji_camera3_main", "usb 0x8007", "liveview"]
    return time_list, name_list

def __check_sat_time(time_list, limit_time_list):
    if len(time_list) != len(limit_time_list):
        return "Fail"

    for i in range(len(time_list)):
        if limit_time_list[i] == 0:
            continue
        if limit_time_list[i] < time_list[i]:
            return "Fail"
    return "Pass"

def sat_time_dump(state, limit_time_list, time_list, name_list, debug=0):
    print(state)
    
    if debug == 0:
        print(limit_time_list)
        print(time_list)
        print(name_list)
        return

    print(len(limit_time_list))
    sf = "{:<25s} {:<8s} {:<8s}"
    for i in range(len(limit_time_list)):
        line = sf.format(name_list[i], str(time_list[i]), str(limit_time_list[i]))
        print(line)

def aosp_init_time_dump(time_list, name_list):
    for i, time in enumerate(time_list):
        name = name_list[i]
        print(f"{name}: {time}ms")

def ansys_systemd_sat_time(debug=0):
    limit_time_list = [0, 0, 0, 0, 0, 0, 0, 5750, 0, 0]
    time_list,name_list = __ansys_sat_time()
    state = __check_sat_time(time_list, limit_time_list)
    sat_time_dump(state, limit_time_list, time_list, name_list, debug)

def ansys_aosp_init_sat_time(debug=0):
    limit_time_list = [0, 0, 0, 0, 0, 0, 0, 5750, 0, 0]
    time_list,name_list = __ansys_aosp_init_time()
    state = __check_sat_time(time_list, limit_time_list)
    sat_time_dump(state, limit_time_list, time_list, name_list, debug)

def ansys_aosp_init_time(debug=0):
    limit_time_list = [0, 0, 0, 0, 0, 0, 0, 5750, 0, 0]
    time_list,name_list = __ansys_aosp_init_time()
    state = __check_sat_time(time_list, limit_time_list)
    aosp_init_time_dump(time_list, name_list)

def is_aosp_init_edition():
    result = subprocess.run(
            "cat /proc/cmdline | grep aosp | wc -l",
            shell=True,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )

    # 解析命令输出
    output = result.stdout.decode().strip()
    return output

def ansys_sat_time(debug=0):
    output = is_aosp_init_edition()
    # 根据当前是aosp_init版本还是systemd版本选择函数
    if output == '1':
        ansys_aosp_init_sat_time()
    elif output == '0':
        ansys_systemd_sat_time()
    else:
        print("Error: Unexpected output from command.")

def print_uasge(debug=0):
    print("""[usage]
python ansys_boot_time.py [option=camera] [debug=0]
option:
    all bootloader camere sat usb
debug:
    0=simple mode
    1=detailed mode
""")

def safe_int(num, default=0):
    try:
        return int(num)
    except:
        return default

function_dict = {
    'all'        : ansys_all_time,
    'bootloader' : ansys_bootloader_time,
    'camera'     : ansys_camera3_time,
    'sat'        : ansys_sat_time,
    'usb'        : ansys_usb_time,
    'aosp_init'  : ansys_aosp_init_time,
}

def main():
    # time.sleep(2)
    output = is_aosp_init_edition()
    if output == '0':
        os.system('systemd-analyze plot > {}'.format(svg_name))

    option = 'camera'
    debug  = 0
    if(len(sys.argv)==2):
        option = sys.argv[1]
    if(len(sys.argv)>=3):
        option = sys.argv[1]
        debug = safe_int(sys.argv[2])

    function_dict.get(option, print_uasge)(debug)

if __name__ == "__main__":
    main()
