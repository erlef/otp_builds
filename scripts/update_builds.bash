#!/bin/bash
set -euo pipefail

main() {
  git config user.name "github-actions[bot]"
  git config user.email "github-actions[bot]@users.noreply.github.com"
  if [[ "${OTP_REF_NAME}" == master ]] || [[ "${OTP_REF_NAME}" == maint* ]]; then
    ref_name="${OTP_REF_NAME}-latest"
  else
    ref_name="${OTP_REF_NAME}"
  fi
  url="https://github.com/${GITHUB_REPOSITORY}/releases/download/${ref_name}/${TGZ}"
  echo "downloading ${url}"
  curl -fsSLO "${url}"

  max_retries=5
  attempt=0
  while [[ ${attempt} -lt ${max_retries} ]]; do
    if push; then
      break
    fi
    attempt=$((attempt + 1))
    echo "Retry ${attempt}/${max_retries} failed. Retrying in 10 seconds..."
    sleep 10
  done

  if [ ${attempt} -eq ${max_retries} ]; then
    echo "Reached maximum retries (${max_retries}). Exiting."
    exit 1
  fi
}

push() {
  local target_branch=main

  git checkout "${target_branch}"
  git reset --hard "origin/${target_branch}"
  git pull origin "${target_branch}"
  build_sha256=$(shasum -a 256 $TGZ | cut -d ' ' -f 1)
  date=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
  mkdir -p builds/
  touch "${BUILDS_CSV}"
  sed -i.bak "/^${OTP_REF_NAME},/d" "${BUILDS_CSV}"
  rm "${BUILDS_CSV}.bak"
  echo -ne "${OTP_REF_NAME},${OTP_REF},${date},${build_sha256},openssl-${OPENSSL_VERSION},wxwidgets-${WXWIDGETS_VERSION}\n$(cat ${BUILDS_CSV})" > "${BUILDS_CSV}"
  sort --reverse --unique -k1,1 -o "${BUILDS_CSV}" "${BUILDS_CSV}"
  git add builds/
  GIT_AUTHOR_NAME="${GITHUB_ACTOR}" \
  GIT_AUTHOR_EMAIL="${GITHUB_ACTOR}@users.noreply.github.com" \
  GIT_COMMITTER_NAME="github-actions[bot]" \
  GIT_COMMITTER_EMAIL="github-actions[bot]@users.noreply.github.com" \
    git commit -m "${BUILDS_CSV}: Add ${OTP_REF_NAME}"
  git push origin "${target_branch}"
}

main $@
