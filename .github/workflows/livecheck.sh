#!/bin/bash
set -e -u
set -o pipefail
set -x

GREP_BIN=$(which ggrep || which grep)

REPO="${GITHUB_REPOSITORY-}"
if [ -z "${REPO}" ]; then
	repo_url=$(git remote get-url origin)
	if [[ $repo_url == git@* ]]; then
		REPO=$(echo "$repo_url" | cut -d : -f 2 | sed s/\\.git//g)
	elif [[ $repo_url == https://* || $repo_url == http://* ]]; then
		REPO=$(echo "$repo_url" | cut -d / -f 4-5 | sed s/\\.git//g)
	fi
fi

if [ -z "${REPO}" ]; then
	exit 1
fi

TAP="${REPO/\/homebrew-//}"



update_formula() {
	formula=${1-}
	old_version=${2-}
	new_version=${3-}

	if [ -z "$formula" ] || [ -z "$old_version" ] || [ -z "$new_version" ]; then
		exit 3
	fi

	latest_version=$(printf '%s\n' "${old_version}" "${new_version}" | sort -r -V | head -n 1)

	if [ "${old_version}" = "${new_version}" ]; then
		echo "Formula/Cask ${formula} version is not changed: ${old_version}."
		exit 0
	elif [ "${old_version}" = "${latest_version}" ]; then
		echo "Formula/Cask ${formula} already up to date: ${old_version}."
		exit 0
	elif [ "${new_version}" = "${latest_version}" ]; then
		echo "Formula/Cask ${formula} ready to update: ${old_version} => ${new_version}."
	else
		echo "Formula/Cask ${formula} unexpected version: ${latest_version}."
		exit 1
	fi

	file=$(brew info "$TAP/$formula" | "${GREP_BIN}" "${formula}\\.rb" | "${GREP_BIN}" "${REPO}" | "${GREP_BIN}" -oP "[^/]*/${formula}\\.rb" )
	update_by_push
}

update_by_version() {
	# Get old sha256
	old_sha256=$("${GREP_BIN}" -oP "sha256 \"\\w+\"" "$file" | sed -e 's/"//g' | cut -d ' ' -f 2)
	# Update version
	sed -i -e "s/version \"${old_version}\"/version \"${new_version}\"/g" "$file"
	# Update sha256
	new_sha256=$(brew fetch "$file" 2>/dev/null | "${GREP_BIN}" 'SHA256:' | sed 's/SHA256: //g' || true)
	if [[ -z "${new_sha256}" ]]; then
		echo "${formula}: Can not get sha256 of ${new_version}"
		exit 4
	fi
	sed -i -e "s/sha256 \"${old_sha256}\"/sha256 \"${new_sha256}\"/g" "$file"

	# Commit to git
	echo "${formula}: update to ${new_version} with sha256=$new_sha256"
}

commit_file() {
	# Commit to git
	echo "${formula}: update to ${new_version} with sha256=$new_sha256"
	git add "$file"
	git --no-pager diff --cached

	git commit -m "$(echo -e "${formula}: update to ${new_version}\n\n This commit has been automatically submitted by Github Actions.")"
}

update_by_pr() {
	BRANCH="bots-$formula-$new_version"

	git checkout develop -f
	# Clean up
	git branch -D "$BRANCH" -f || true
	git push --delete origin "$BRANCH" || true

	# Prepare new branch
	git checkout -b "$BRANCH"
	
	update_by_version

	# Commit to git
	commit_file
	# Push new branch
	git push -u origin "$BRANCH"

	# 
	pr=$(gh pr create -a '@me' -B develop -H "$BRANCH" -f -t "${formula}: update to ${new_version}" | rev | cut -d / -f 1 | rev)
	gh pr edit --add-label pr-pull
	#gh pr review "$pr" -a
	#gh pr merge "$pr" --auto --merge
	# recover
	git checkout develop -f

}


update_by_push() {
	git pull --rebase
	git checkout -- "$file"
	update_by_version
	commit_file
	git pull --rebase
	git push
}



if [ -z "${1-}" ]; then
	git config --local user.name "Github Actions"
	git config --local user.email "hu2008yinxiang@163.com"
	brew tap $TAP
	tap_repo=$(brew --repo $TAP)
	brew livecheck --json --tap "$TAP" \
	 | jq -r '. | map({cask: .cask, current: .version.current, latest: .version.latest}) | map(.cask + " " + .current + " " + .latest) | .[]' \
	 | while read line || [[ -n "$line" ]]; do
		update_formula $line
	done
	exit 0
fi


