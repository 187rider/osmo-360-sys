# Copyright (c) 2014-2015, 2020-2021 The Linux Foundation. All rights reserved.
# Copyright (c) 2022-2023 Qualcomm Innovation Center, Inc. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 and
# only version 2 as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

import re
import sys
import os
import struct

class KpanicConsle(object):

    def __init__(self, outfile):
        try:
            out_file = open(outfile, 'wt')
        except:
            print("could not open out_file")
            sys.exit(1)
        self.outfile = out_file
        # 全局变量保存文件描述符、起始地址和大小
        self.file_info = []
        self.descs_addr = 0
        self.infos_addr = 0
        self.data_addr = 0
        self.prb_addr = 0

    def get_prb_addr(self, file_path):
        pattern = re.compile(r"log_buf_prb_addr:\s*(0x[0-9a-fA-F]+)")
        kboot_log = os.path.join(file_path, "md_KBOOT_LOG.BIN")
        with open(kboot_log, 'r') as file:
            for line in file:
                match = pattern.search(line)
                if match:
                # 提取匹配的值
                    self.prb_addr = int(match.group(1),16)
                    return self.prb_addr
        return None

    def parse_file(self, file_path, valid_filenames):
        """
        解析文件，提取起始地址、大小和文件名，并根据条件打开文件生成fd
        :param file_path: 输入文件路径
        :param valid_filenames: 有效的文件名列表
        """
        dump_info = os.path.join(file_path, "dump_info.txt")
        with open(dump_info, 'r') as f:
            for line in f:
                parts = line.split()
                if len(parts) < 4:
                    continue

                start_address = int(parts[1], 16)
                size = int(parts[2], 16)
                filename = parts[3]

                if filename in valid_filenames:
                    if filename == "md_LOG_DESC.BIN":
                        self.descs_addr = start_address
                    if filename == "md_LOG_INFO.BIN":
                        self.infos_addr = start_address
                    if filename == "md_KLOGBUF.BIN":
                        self.data_addr = start_address
                    try:
                        file = os.path.join(file_path, filename)
                        fd = open(file, 'rb')
                        self.file_info.append((fd, start_address, size))
                    except FileNotFoundError:
                        print(f"File not found: {file}")
    def read_physical(self, addr, length):
        if not isinstance(addr, int) or not isinstance(length, int):
            return None
        """
        根据地址判断属于哪个fd，并从fd中读取数据
        :param address: 输入地址
        :param length: 读取数据的长度
        :return: 读取的数据
        """
        for fd, start_address, size in self.file_info:
            if start_address <= addr < start_address + size:
                offset = addr - start_address
                fd.seek(offset)
                return fd.read(length)

        return None
    def read_string(self, addr_or_name, format_string):
        """Reads data using a format string.

        Reads data from addr_or_name using format_string (which should be a
        struct.unpack format).

        Returns the tuple returned by struct.unpack.
        """
        addr = addr_or_name
        s = None
        s = self.read_physical(addr, struct.calcsize(format_string))
        if (s is None) or (s == ''):
            return None
        return struct.unpack(format_string, s)
    def read_ulong(self, addr_or_name):
        """returns a value corresponding to half the word size"""
        s = self.read_string(addr_or_name, '<Q')
        return s[0] if s is not None else None
    def read_u64(self, addr_or_name):
        """returns a value guaranteed to be 64 bits"""
        s = self.read_string(addr_or_name, '<Q')
        return s[0] if s is not None else None
    def read_u32(self, addr_or_name):
        """returns a value guaranteed to be 32 bits"""
        s = self.read_string(addr_or_name, '<I')
        return s[0] if s is not None else None
    def read_u16(self, addr_or_name):
        """returns a value guaranteed to be 16 bits"""
        s = self.read_string(addr_or_name, '<H')
        return s[0] if s is not None else None
    def read_pointer(self, addr_or_name):
        return self.read_u64(addr_or_name)
    def read_cstring(self, addr_or_name, max_length=100):
        """Reads a C string."""
        addr = addr_or_name
        s = None
        s = self.read_physical(addr, max_length)
        if s is not None:
            a = s.decode('ascii', 'ignore')
            return a.split('\0')[0]
        else:
            return s

    def extract_lockless_dmesg(self):
        #prb_addr = self.read_pointer('prb')
        #off = self.field_offset('struct printk_ringbuffer', 'desc_ring')
        prb_addr = self.prb_addr
        off = 0
        desc_ring_addr = prb_addr + off

        #off = self.field_offset('struct prb_desc_ring', 'count_bits')
        off = 0
        desc_ring_count = 1 << self.read_u32(desc_ring_addr + off)
        #desc_sz = self.sizeof('struct prb_desc')
        desc_sz = 0x18
        #off = self.field_offset('struct prb_desc_ring', 'descs')
        #descs_addr = self.read_ulong(desc_ring_addr + off)
        descs_addr = self.descs_addr

        #info_sz = self.sizeof('struct printk_info')
        info_sz = 0x58
        #off = self.field_offset('struct prb_desc_ring', 'infos')
        #infos_addr = self.read_ulong(desc_ring_addr + off)
        infos_addr = self.infos_addr

        #off = self.field_offset(
        #                        'struct printk_ringbuffer', 'text_data_ring')
        off = 0x30
        text_data_ring_addr = prb_addr + off

        #off = self.field_offset('struct prb_data_ring', 'size_bits')
        off = 0
        text_data_sz = 1 << self.read_u32(text_data_ring_addr + off)
        #off = self.field_offset('struct prb_data_ring', 'data')
        #data_addr = self.read_ulong(text_data_ring_addr + off)
        data_addr = self.data_addr

        # sv_off = self.field_offset('struct prb_desc', 'state_var')
        # off = self.field_offset('struct prb_desc','text_blk_lpos')
        # begin_off = off + self.field_offset(
                                        # 'struct prb_data_blk_lpos', 'begin')
        # next_off = off + self.field_offset(
                                        # 'struct prb_data_blk_lpos', 'next')
        # ts_off = self.field_offset('struct printk_info', 'ts_nsec')
        # callerid_off = self.field_offset('struct printk_info', 'caller_id')
        # len_off = self.field_offset('struct printk_info', 'text_len')
        sv_off = 0
        off = 8
        begin_off = 8
        next_off = 0x10
        ts_off = 8
        callerid_off = 0x14
        len_off = 0x10

        desc_committed = 1
        desc_finalized = 2
        #desc_sv_bits = self.sizeof('long') * 8
        desc_sv_bits = 0x40
        desc_flags_shift = desc_sv_bits - 2
        desc_flags_mask = 3 << desc_flags_shift
        desc_id_mask = ~desc_flags_mask

        #off = self.field_offset('struct prb_desc_ring','tail_id')
        off = 0x20
        tail_id = self.read_ulong(desc_ring_addr + off)
        #off = self.field_offset('struct prb_desc_ring','head_id')
        off = 0x18
        head_id = self.read_ulong(desc_ring_addr + off)

        did = tail_id

        dmesg_list={}
        while True:
            ind = did % desc_ring_count
            desc_off = desc_sz * ind
            info_off = info_sz * ind

            # skip non-committed record
            state = 3 & (self.read_ulong(descs_addr + desc_off +
                                            sv_off) >> desc_flags_shift)
            if state != desc_committed and state != desc_finalized:
                if did == head_id:
                    break
                did = (did + 1) & desc_id_mask
                continue

            begin = self.read_ulong(descs_addr + desc_off +
                                                begin_off) % text_data_sz
            end = self.read_ulong(descs_addr + desc_off +
                                                next_off) % text_data_sz

            if begin & 1 == 1:
                text = ""
            else:
                if begin > end:
                    begin = 0

                text_start = begin + 8
                text_len = self.read_u16(infos_addr +
                                                    info_off + len_off)

                if end - text_start < text_len:
                    text_len = end - text_start
                if text_len < 0:
                    text_len = 0

                text = self.read_cstring(data_addr +
                                                    text_start, text_len)

            time_stamp = self.read_u64(infos_addr +
                                                    info_off + ts_off)
            caller_data = self.read_u32(infos_addr +
                                                    info_off + callerid_off)
            tid_info = "T"
            if (caller_data & 0x80000000):
                tid_info = "C"

            caller_id_data = caller_data & ~0x80000000
            pid = caller_id_data
            caller_id_data = tid_info + str(caller_id_data)
            for line in text.splitlines():
                msg = u"[{time:12.6f}][{caller_id_data:>6}] {line}\n".format(
                    time=time_stamp / 1000000000.0,
                    line=line,caller_id_data=caller_id_data)
                #print(msg, write_to_file)
                self.outfile.write(msg)

            if did == head_id:
                break
            did = (did + 1) & desc_id_mask
        return dmesg_list

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python kpanic_console.py <file_path> <out_folder>")
        sys.exit(1)

    file_path = sys.argv[1]
    out_folder = sys.argv[2]
    # 定义有效的文件名列表
    valid_filenames = ["md_KDATABSS.BIN", "md_LOG_DESC.BIN", "md_LOG_INFO.BIN", "md_KLOGBUF.BIN"]

    kpanic_console = KpanicConsle(out_folder)
    log_buf_prb_addr = kpanic_console.get_prb_addr(file_path)
    if log_buf_prb_addr:
        kpanic_console.parse_file(file_path, valid_filenames)
        kpanic_console.extract_lockless_dmesg()
    else:
        print("log_buf_prb_addr not found")

