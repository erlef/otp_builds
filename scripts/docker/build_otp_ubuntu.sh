#!/bin/bash
set -euox pipefail

: "${OTP_REF_NAME:?OTP_REF_NAME not set}"
: "${OTP_REF:?OTP_REF not set}"

echo "Building ${OTP_REF_NAME} (${OTP_REF})"

src_dir="otp-${OTP_REF}"
wget -nv "https://github.com/erlang/otp/archive/${OTP_REF}.tar.gz" -O otp-src.tar.gz
tar -zxf otp-src.tar.gz
rm otp-src.tar.gz
chmod -R 777 "${src_dir}"

cd "${src_dir}"
./configure --with-ssl
make -j"$(getconf _NPROCESSORS_ONLN)"
make -j"$(getconf _NPROCESSORS_ONLN)" release
make -j"$(getconf _NPROCESSORS_ONLN)" release_docs DOC_TARGETS="chunks"
cd ..

mv "${src_dir}"/release/*/ "${OTP_REF_NAME}"
(cd "${OTP_REF_NAME}" && ./Install -sasl "${PWD}")
tar -zcf "out/${OTP_REF_NAME}.tar.gz" "${OTP_REF_NAME}"
chown --reference=out "out/${OTP_REF_NAME}.tar.gz"
