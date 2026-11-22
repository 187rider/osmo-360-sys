echo "shell param:"
echo "print param:$1 $2 $3"

MOUNT_ROOT=$1
TEST_ROOT="${MOUNT_ROOT}/DCIM"
FAKE_JPG_FILE_CONTENT="Fake jpg file only for test"

mkdir -p ${TEST_ROOT}
cd ${TEST_ROOT}
mkdir ${TEST_ROOT}/$2
echo ${FAKE_JPG_FILE_CONTENT} > ${TEST_ROOT}/$2/$3
