#!/bin/bash
set -euo pipefail

usage() {
  cat<<EOF
ref_name=OTP-27.1; \
  GITHUB_REF=wm-initial \
  OTP_DIR=$PWD/tmp/otp \
  OTP_REF_NAME=$ref_name \
  OTP_REF=$(gh api repos/erlang/otp/commits/$OTP_REF_NAME --jq .sha) \
  OTP_ARCH=arm64 \
  ./scripts/upload.bash
EOF
}

main() {
  : "${GITHUB_REPOSITORY:=erlef/otp_builds}"

  if [ "${OTP_REF_NAME}" = master ] || echo "${OTP_REF_NAME}" | grep -q "^maint"; then
    ref_name="${OTP_REF_NAME}-latest"
    notes="Automated build for https://github.com/erlang/otp/tree/${OTP_REF_NAME}."
  else
    ref_name="${OTP_REF_NAME}"
    notes="Automated build for https://github.com/erlang/otp/releases/tag/${OTP_REF_NAME}."
  fi

  # TODO:
  # git remote add upstream https://github.com/erlang/otp
  # git fetch upstream
  # git tag $ref_name $OTP_REF --force
  # git push origin $ref_name --force

  if ! gh release view $ref_name; then
    if ! echo "$ref_name" | grep -qE 'rc|maint|master'; then
      latest="--latest=false"

      if [ -f builds/macos-arm64.txt ]; then
        latest_version=`cat builds/macos-arm64.txt | cut -d" " -f1 | grep OTP- | sed 's/OTP-//' | sort --reverse -V | head -1`
        version=$(echo "$ref_name" | sed 's/OTP-//')

        if [ $(printf "%s\n%s" "$latest_version" "$version" | sort --reverse -V | head -1) != "$latest_version" ]; then
          latest="--latest"
        fi
      fi
    fi

    # Initial commit
    target=b5893a3c3a8d0ab54be5d04de450b24d9e5aa149

    gh release create \
      --repo "${GITHUB_REPOSITORY}" \
      --title "$ref_name" \
      --notes "$notes" \
      --target "$target" \
      $latest \
      $ref_name
  fi

  mkdir -p tmp
  tgz="$PWD/tmp/${OTP_REF_NAME}-macos-${OTP_ARCH}.tar.gz"
  tar czf $tgz --cd $OTP_DIR .

  gh release upload \
    --repo "${GITHUB_REPOSITORY}" \
    --clobber \
    $ref_name \
    $tgz

  gh workflow run update_builds_txt.yaml \
    --repo "${GITHUB_REPOSITORY}" \
    --ref "${GITHUB_REF}" \
    --field otp-ref-name="${OTP_REF_NAME}" \
    --field otp-ref="${OTP_REF}" \
    --field arch="${OTP_ARCH}"
}

main $@
