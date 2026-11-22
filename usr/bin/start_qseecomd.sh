#!/bin/sh
/usr/bin/find -L /dev/dma_heap/qcom,qseecom-ta -maxdepth 1 -type f -exec chown root:system {} +
/usr/bin/find -L /dev/dma_heap/qcom,qseecom-ta -maxdepth 1 -type f -exec chmod 0660 {} +
/usr/bin/find -L /dev/dma_heap/qcom,qseecom -maxdepth 1 -type f -exec chown root:system {} +
/usr/bin/find -L /dev/dma_heap/qcom,qseecom -maxdepth 1 -type f -exec chmod 0660 {} +
/usr/bin/qseecomd
