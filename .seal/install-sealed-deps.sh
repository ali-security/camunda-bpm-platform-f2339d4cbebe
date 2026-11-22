#!/usr/bin/env bash
# Seal: builds Gson 2.8.9 with the fix for CVE-2025-53864 / sonatype-2025-000535 (a nesting limit in JsonReader,
# upstream google/gson 1039427ff0100293dd3cf967a53a55282c0fef6b) and installs it into the local Maven repository
# under the public coordinates, so the engine build resolves it and shades it as camundajar.impl.com.google.gson.
# The patch is the one sealed com.google.code.gson:gson 2.8.9+sp1 ships (patches/CVE-2025-53864.llm.patch).
set -euo pipefail

GSON_COMMIT=6a368d89da37917be7714c3072b8378f4120110a  # tag gson-parent-2.8.9

# Gson 2.8.9 compiles with -source 1.6, which JDK 17 rejects; the sealed gson 2.8.9+sp1 was built on JDK 11.
# The job sets JDK 11 up ahead of JDK 17, which leaves JAVA_HOME_11_X64 behind for this script.
if [ -z "${JAVA_HOME_11_X64:-}" ]; then
  echo "JAVA_HOME_11_X64 is not set: set up JDK 11 before running this script" >&2
  exit 1
fi
export JAVA_HOME="${JAVA_HOME_11_X64}"
export PATH="${JAVA_HOME}/bin:${PATH}"

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT

git init --quiet "${work}/gson"
git -C "${work}/gson" fetch --quiet --depth 1 https://github.com/google/gson.git "${GSON_COMMIT}"
git -C "${work}/gson" checkout --quiet FETCH_HEAD
git -C "${work}/gson" apply "${here}/gson/CVE-2025-53864.patch"
# Runs the Gson test classes the nesting-limit patch adds tests to, so the fix is exercised before it is shaded.
mvn -B -f "${work}/gson/pom.xml" -pl gson -am install -Dmaven.javadoc.skip=true -Dgpg.skip=true \
  -Dtest=JsonReaderTest,JsonTreeReaderTest,JsonParserTest,ObjectTypeAdapterTest,ObjectTest -Dsurefire.failIfNoSpecifiedTests=false
echo "installed Gson 2.8.9 with the nesting limit into ${HOME}/.m2"
