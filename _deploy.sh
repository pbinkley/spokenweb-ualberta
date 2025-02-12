github_token="<bearer_token>"
deploy_loc="<folder_to_deploy_to>"
temp_folder="<temporary_working_folder>"

mkdir -p "${temp_folder}"

artifact_info=$(curl -L \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/SpokenWebAlberta/spokenweb-ualberta/actions/artifacts)

download_url=$(echo "$artifact_info" | jq -r ".artifacts[0].archive_download_url")

echo "$download_url"

http_code=$(curl -L \
  --write-out "%{http_code}\n" \
  -o "${temp_folder}/download.zip" \
  -H "Authorization: Bearer $github_token" \
  "$download_url")

if [[ "${http_code}" == "403" ]]
then
  echo "I do not have permission to download artifact file, is my github_token still valid?"
elif [[ "${http_code}" == "410" ]]
then
  echo "The build artifacts have expired, please re-run build."
elif [[ "${http_code}" != "200" ]]
then
  echo "Got code: ${http_code}"
  echo "Failed to download for other reasons. Please try again later, and if this problem persists the build script is likely broken."
else
  unzip -d ${temp_folder} "${temp_folder}/download.zip"
  rm -R $deploy_loc/*
  #mkdir -p "${deploy_loc}"
  mkdir -p "${temp_folder}/_site"
  tar -xvf "${temp_folder}/artifact.tar" -C "${temp_folder}/_site"
  cp -r "${temp_folder}/_site/." "${deploy_loc}/"
fi

rm -R "${temp_folder}"
