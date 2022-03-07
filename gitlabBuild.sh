#!/usr/bin/env bash

# ===============================================================================
#          FILE:  gitlabBuild.sh
#
#         USAGE:  gitlabBuild [<ojs>]
#
#   DESCRIPTION:  A script to generate tags to let gitLab build images.
#
#    PARAMETERS:
#         <ojs>:  (optional) The release version that you like to build.
#                 If any, all the existing versions will be created.
#  REQUIREMENTS:  mapfile
#     TODO/BUGS:  ---
#         NOTES:  ---
#       AUTHORS:  Marc Bria.
#  ORGANIZATION:  Public Knowledge Project (PKP)
#       LICENSE:  GPL 3
#       CREATED:  06/03/2022 16:45:15 CEST
#       UPDATED:  }d{
#      REVISION:  1.0
#===============================================================================

set -Eeuo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

# You can pass the specific version of the stack you like to create.
ojsVersions=( "$@" )

# Otherwise, all the versions for the existing folders will be recreated.
if [ ${#ojsVersions[@]} -eq 0 ]; then
	printf "Warning: This action is destructive. ALL former version folders will be removed.\n"
	[[ "$(read -e -p 'Are you sure you want to continue? [y/N]> '; echo $REPLY)" == [Yy]* ]]

	# Warning: Versions need to fit with OJS tag names:
	mapfile -t ojsVersions < versions.list
else
	if [ ${#ojsVersions[@]} -eq 1 ]; then
		if [[ -d "versions/$ojsVersions" ]]; then
			printf "Warning: This action is destructive. Existing version $ojsVersions will be removed.\n"
			[[ "$(read -e -p 'Are you sure you want to continue? [y/N]> '; echo $REPLY)" == [Yy]* ]]
		fi
		mkdir -p "versions/$ojsVersions"
	else
		printf "Only one param is accepted.\n"
		exit 0
	fi
fi

# All the OJS versions:
ojsVersions=( "${ojsVersions[@]%/}" )

# All the OS:
osVersions=( 'alpine' )

# All the Webservers:
webServers=(  'apache' )
# webServers=(  'apache' 'nginx' )

# All PHP versions:
phpVersions=( 'php5' 'php70' 'php73' 'php74' )
# phpVersions=( 'php5' 'php70' 'php73' )

# PHP support for each ojs version:
mapfile -t php5  < ./platforms/php5.list
mapfile -t php70 < ./platforms/php70.list
mapfile -t php73 < ./platforms/php73.list
mapfile -t php74 < ./platforms/php74.list

printf "\n\nBUILDING OJS OFFICIAL DOCKER STACKS\n"
printf "===================================\n\n"

for ojs in "${ojsVersions[@]}"; do
	for os in "${osVersions[@]}"; do
		for server in "${webServers[@]}"; do
			for php in "${phpVersions[@]}"; do

				# OJS tagging changed it syntax between versions.
				# To keep a single criteria, in Docker the syntax is
				# unified and we always use the version number (without prefix).
				# Ie: "ojs-3_1_1-4 will" be tagged as "3_1_1-4"
				ojsNum=${ojs#"ojs-"}

				build=0
				case $php in
					php5 )
						[[ " ${php5[@]} " =~ " ${ojs} " ]] && build=1
					;;
					php70 )
						[[ " ${php70[@]} " =~ " ${ojs} " ]] && build=1
					;;
					php72 )
						[[ " ${php72[@]} " =~ " ${ojs} " ]] && build=1
					;;
					php73 )
					    [[ " ${php73[@]} " =~ " ${ojs} " ]] && build=1
					;;
					php74 )
					    [[ " ${php74[@]} " =~ " ${ojs} " ]] && build=1
					;;
				esac

				if [ ${build} -eq 1 ]; then
					if [[ -d "templates/webServers/$server/$php" ]]; then
						printf ">> BUILDING:    $ojsNum: [$server] $php (over $os)\n"
						# git tag -d $ojsNum &
						# git push --delete origin $ojsNum & 
						git tag $ojsNum -a -m "$ojsNum: [$server] $php (over $os)" &
						git push origin $ojsNum --force 
					else
						printf "   ERROR: Refusing to create a tag for $ojsNum."
						printf " (Missing template for: templates/webservers/$server/$php)\n\N"
						exit 0
					fi
				else
					printf "   DISABLED: Refusing to create a tag for $ojsNum."
					printf " ($ojsNum: [$server] $php (over $os))\n"
				fi
			done
		done
		printf "\n"
	done
done

echo ""
echo "Work done. Now you can review it and push with:"
echo "- List all tags: $ git tag"
echo "- Push all tags: $ git push origin --tags"
