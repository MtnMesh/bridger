#!/usr/bin/bash
set -e
echo "testing"

influx task create \
  --name "importmodels" \
  --org MtnMesh \
  --every 24h \
  --type "flux" \
  --file - <<EOF
import "http/requests"
import "experimental/json"
import "array"
import "influxdata/influxdb"
option task = { 
  name: "importmodels",
  every: 24h,
}

response = requests.get(url: "https://api.meshtastic.org/resource/deviceHardware")

data = json.parse(data: response.body)

models = array.from(rows: data)
  |> group(columns: ["hwModel"])
  |> map(fn: (r) => ({r with hwModel: int(v: r.hwModel)}))
  |> reduce(
      fn: (r, accumulator) => ({
        _measurement: "modelinfo",
        hwModel: r.hwModel,
        _time: now(),
        architecture: r.architecture,
        displayName: if accumulator.displayName == "" then r.displayName else accumulator.displayName + ", " + r.displayName
      }),
      identity: {_measurement: "", hwModel: 0, displayName: "", architecture: "", _time: 2024-01-01}
    )
  |> group(columns: ["_measurement", "architecture", "displayName"])

models
  |> influxdb.wideTo(bucket: "meshtastic")
EOF
