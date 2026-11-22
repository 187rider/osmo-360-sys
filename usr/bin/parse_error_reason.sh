get_bsp_fail_reason()
{
    if [ $1 == 1 ]; then
        aging_fail_reason="bsp_cpu"
    elif [ $1 == 2 ]; then
        aging_fail_reason="bsp_ddr"
    elif [ $1 == 3 ]; then
        aging_fail_reason="bsp_emmc_dd"
    elif [ $1 == 4 ]; then
        aging_fail_reason="bsp_emmc_write"
    elif [ $1 == 5 ]; then
        aging_fail_reason="bsp_sd_dd"
    elif [ $1 == 6 ]; then
        aging_fail_reason="bsp_sd_write"
    elif [ $1 == 7 ]; then
        aging_fail_reason="bsp_sd_not_found"
    elif [ $1 == 8 ]; then
        aging_fail_reason="bsp_no_sample_data"
    else
        aging_fail_reason="unknown"
    fi

    echo $aging_fail_reason
}

get_perception_fail_reason()
{
    if [ $1 == 1 ]; then
        aging_fail_reason="syslog contains error"
    elif [ $1 == 2 ]; then
        aging_fail_reason="load image fail"
    elif [ $1 == 3 ]; then
        aging_fail_reason="usb init fail"
    elif [ $1 == 4 ]; then
        aging_fail_reason="fname file not exist"
    elif [ $1 == 5 ]; then
        aging_fail_reason="connection.log file not exist"
    elif [ $1 == 6 ]; then
        aging_fail_reason="syslog overflow"
    elif [ $1 == 7 ]; then
        aging_fail_reason="reset"
    else
        aging_fail_reason="unknown"
    fi

    echo $aging_fail_reason
}

get_navigation_fail_reason()
{
    if [ $1 == 2 ]; then
        aging_fail_reason="nav_dsp2_fail"
    elif [ $1 == 3 ]; then
        aging_fail_reason="nav_dsp3_fail"
    else
        aging_fail_reason="unknown"
    fi

    echo $aging_fail_reason
}

get_camera_fail_reason()
{
    if [ $1 == 1 ]; then
        aging_fail_reason="set capture workmode"
    elif [ $1 == 2 ]; then
        aging_fail_reason="set record workmode"
    elif [ $1 == 3 ]; then
        aging_fail_reason="set playback workmode"
    elif [ $1 == 4 ]; then
        aging_fail_reason="start record"
    elif [ $1 == 5 ]; then
        aging_fail_reason="check recording status"
    elif [ $1 == 6 ]; then
        aging_fail_reason="start video playback"
    elif [ $1 == 7 ]; then
        aging_fail_reason="stop video playback"
    elif [ $1 == 8 ]; then
        aging_fail_reason="stop record"
    elif [ $1 == 9 ]; then
        aging_fail_reason="single capture"
    elif [ $1 == 10 ]; then
        aging_fail_reason="burst capture"
    elif [ $1 == 11 ]; then
        aging_fail_reason="AEB capture"
    elif [ $1 == 12 ]; then
        aging_fail_reason="formart sd card"
    elif [ $1 == 13 ]; then
        aging_fail_reason="get video dcf info"
    elif [ $1 == 14 ]; then
        aging_fail_reason="input argument"
    else
        aging_fail_reason="unknown"
    fi

    echo $aging_fail_reason
}

get_codec_fail_reason()
{
    if [ $1 == 10 ]; then
        aging_fail_reason="input_video_not_exist"
    elif [ $1 == 11 ]; then
        aging_fail_reason="input_video_md5_error"
    elif [ $1 == 21 ]; then
        aging_fail_reason="vdec_output_not_exist"
    elif [ $1 == 22 ]; then
        aging_fail_reason="vdec_output_md5_error"
    elif [ $1 == 50 ]; then
        aging_fail_reason="input_jpg_not_exist"
    elif [ $1 == 51 ]; then
        aging_fail_reason="input_jpg_md5_error"
    elif [ $1 == 61 ]; then
        aging_fail_reason="jdec_output_not_exist"
    elif [ $1 == 62 ]; then
        aging_fail_reason="jdec_output_md5_errorargument"
    else
        aging_fail_reason="unknown"
    fi

    echo $aging_fail_reason
}

get_fc_fail_reason()
{
    if [ $1 == 8 ]; then
        aging_fail_reason="fc_acc"
    elif [ $1 == 9 ]; then
        aging_fail_reason="fc_gypo"
    elif [ $1 == 10 ]; then
        aging_fail_reason="fc_baro"
    elif [ $1 == 11 ]; then
        aging_fail_reason="fc_compass"
    elif [ $1 == 12 ]; then
        aging_fail_reason="fc_gps_uart"
    elif [ $1 == 13 ]; then
        aging_fail_reason="fc_recorder"
    elif [ $1 == 14 ]; then
        aging_fail_reason="fc_esc_uart"
    elif [ $1 == 15 ]; then
        aging_fail_reason="fc_bat_uart485"
    elif [ $1 == 16 ]; then
        aging_fail_reason="fc_sdr_uart"
    elif [ $1 == 17 ]; then
        aging_fail_reason="fc_rc"
    elif [ $1 == 18 ]; then
        aging_fail_reason="fc_vo"
    elif [ $1 == 31 ]; then
        aging_fail_reason="fc_esc_spi"
    elif [ $1 == 32 ]; then
        aging_fail_reason="fc_e1e_baro"
    elif [ $1 == 35 ]; then
        aging_fail_reason="fc_pigeon_baro"
    else
        aging_fail_reason="unknown"
    fi

    echo $aging_fail_reason
}

get_fail_reason()
{
    echo get fail reason. $1 $2
    headtitle=$1
    link_str="aging_test_check_link"
    fc_str="fc_aging_test"
    bsp_cpu_str="bsp_cpu_aging_test"
    bsp_ddr_str="bsp_ddr_aging_test"
    bsp_emmc_sd_str="bsp_emmc_sd_aging_test"
    perception_str="vp_log_check.sh"
    navigation_str="nav_log_check.sh"
    camera_str="camera_aging_test"
    codec_str="codec_aging_test"

    if [[ $1 == *$link_str* ]]; then
        echo "to get fail reason of link test"
        get_link_fail_reason $2
        headtitle="aging_link"
    elif [[ $1 == *$fc_str* ]]; then
        echo "to get fail reason of fc"
        get_fc_fail_reason $2
        headtitle="fc"
    elif [[ $1 == *$bsp_cpu_str* ]]||[[ $1 == *$bsp_ddr_str ]]||[[ $1 == *$bsp_emmc_sd_str ]]; then
        echo "to get fail reason of bsp or codec"
        get_bsp_fail_reason $2
        headtitle="bsp"
    elif [[ $1 == *$perception_str* ]]; then
        echo "to get fail reason of perception"
        get_perception_fail_reason $2
        headtitle="perception"
    elif [[ $1 == *$navigation_str* ]]; then
        echo "to get fail reason of navigation"
        get_navigation_fail_reason $2
        headtitle="navigation"
    elif [[ $1 == *$camera_str* ]]; then
        echo "to get fail reason of camera"
        get_camera_fail_reason $2
        headtitle="camera"
    elif [[ $1 == *$codec_str* ]]; then
        echo "to get fail reason of codec"
        get_codec_fail_reason $2
        headtitle="codec"
    else
        echo "fail to get fail reason"
        aging_fail_reason="unknown"
    fi
}
