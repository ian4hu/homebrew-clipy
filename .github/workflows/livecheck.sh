#!/bin/bash
set -x

: "${SUB_CMD:=false}"

REPO="${GITHUB_REPOSITORY}"
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


if [ -z "$1" ]; then
	if [ "${SUB_CMD}" = "true" ]; then
		echo "Error when retrive updates."
		exit 2
	fi
	git config --local user.name "Github Actions"
	git config --local user.email "hu2008yinxiang@163.com"
	brew tap $TAP
	local tap_repo=$(brew --repo $TAP)
	rm -rf "$tap_repo"
	ln -s `pwd` "$tap_repo"
	brew livecheck --tap "$TAP" | cut -d ' ' -f 1,3,5 | SUB_CMD=true xargs -L 1 bash "$0"
	exit 0
fi

formula=$1
old_version=$2
new_version=$3

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

file=$(brew edit --print-path "$TAP/$formula" | grep -oP "$REPO/.*" | cut -d / -f 3-)

update_by_version() {
	# Update version
	sed -i -e "s/version \"${old_version}\"/version \"${new_version}\"/g" "$file"
	# Update sha256
	sha256=$(brew fetch ./Casks/ian4hu-clipy.rb 2>/dev/null | grep 'SHA256' | cut -d ' ' -f 2)
	sed -E -i -e "s/sha256 \"\\w+\"/sha256 \"${sha256}\"/g" "$file"

	# Commit to git
	echo "${formula}: update to ${new_version} with sha256=$sha256"
}

commit_file() {
	# Commit to git
	echo "${formula}: update to ${new_version} with sha256=$sha256"
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

update_by_push



