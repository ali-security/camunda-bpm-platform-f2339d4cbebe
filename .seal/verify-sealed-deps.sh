#!/usr/bin/env bash
# Seal: fails unless the engine jar built from this tree carries the sealed Gson,
# i.e. the shaded JsonReader has the nesting limit (JsonReader.setNestingLimit).
set -euo pipefail

jar="${HOME}/.m2/repository/org/camunda/bpm/camunda-engine/7.20.0/camunda-engine-7.20.0.jar"
tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

unzip -p "${jar}" camundajar/impl/com/google/gson/stream/JsonReader.class > "${tmp}/JsonReader.class"
if ! grep -aq setNestingLimit "${tmp}/JsonReader.class"; then
  echo "the shaded Gson JsonReader in ${jar} has no nesting limit" >&2
  exit 1
fi
echo "the shaded Gson JsonReader has the nesting limit"
