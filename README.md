# Angel: iOS prototype apps (2014)

Angel was the first product idea at Safetracing, the company I co-founded: a small Bluetooth
Low Energy tag for your keys or valuables, and an iPhone app that tells you when the tag moves,
when you walk away from it (range about 25 m), or when it is out of reach. I wrote the iOS apps.

This repository is the prototype from February 2014. A Texas Instruments SensorTag stands in
for the Angel tag. The older snapshot of the same app is
[kirbac/iOS-Angel-Demo](https://github.com/kirbac/iOS-Angel-Demo).

## What is in here

| Folder | What it is |
|---|---|
| `AngelDemo/` | The Angel app: login, finding the tag, live readings, and the alerts. |
| `AngelInventory/` | A barcode scanner that reads a customer ID code and keeps it on the device. |
| `SensorTag/`, `Over the Air Download  Example Source Code 1.1.0/` | Texas Instruments' SensorTag sample apps, version 1.1.0. AngelDemo compiles `BLEDevice`, `BLEUtility` and `Sensors` from here. |
| `BTLE_Transfer/` | Apple's CoreBluetooth sample. |
| `AngelDemo/Examples/`, `AngelDemo/Documentation/` | ZBar SDK samples and documentation, left over from the first scanner setup. The apps no longer use ZBar. |

## How AngelDemo works

1. **Log in**, or skip.
2. **Pair.** The app scans for Bluetooth LE devices and looks for the SensorTag service
   `F000AA00-0451-4000-B000-000000000000`. When it finds one, the Angel icon appears.
3. **Watch.** Tapping the icon connects to the tag. The Info tab shows temperature, humidity
   and signal strength (RSSI). The map tab shows where you are.
4. **Alerts**, each switched on in the Info tab:
   - *Your Angel moved!* when the accelerometer reports movement.
   - *Did you forget your angel?* when the signal drops to between -80 and -90 dBm, which
     means you are walking away from it.
   - *Your Angel is lost!* when the tag disconnects.

## Running it

You need a recent Xcode. The apps target iOS 15 and later.

1. Open `AngelDemo/AngelDemo.xcodeproj`, pick an iPhone simulator and press Run.
2. Log in as `alex` / `1234`, or tap **Skip**.
3. The Simulator has no Bluetooth, so tap **Try demo mode**. It feeds the Info tab simulated
   readings. Switch on *Motion Alert* and *Forget Alert* to see the alerts.

For the scanner, open `AngelInventory/AngelInventory.xcodeproj`. The Simulator has no camera
either, so **Scan barcode** offers a sample code instead.

On an iPhone, AngelDemo looks for a real CC2541 SensorTag; that path has not been tried with
hardware since 2014.

## The 2026 update

The code last built with Xcode 5 for iOS 7. To bring it back:

- Raised the deployment target to iOS 15, removed hard-coded library paths from the original
  Macs, and added a launch screen and the Bluetooth, location and camera permission texts
  that iOS now requires.
- Replaced APIs Apple has removed: `UIAlertView`, `CBPeripheral.isConnected` and
  `CBPeripheral.RSSI`.
- Replaced ZBar in AngelInventory with the barcode reader built into AVFoundation. ZBar was
  only ever built for 32-bit devices.
- Fixed a few bugs: the info screen was presented twice, gyroscope readings were always zero,
  and the value labels faded out for good.
- Added demo mode.

## Credits and licences

- The Angel apps: © 2014 Ugur Kirbac.
- SensorTag sample code: © 2012 Texas Instruments Incorporated.
- BTLE Transfer: Apple sample code.
- ZBar: © 2007-2011 Jeff Brown, LGPL 2.1 (see `AngelDemo/LICENSE` and `AngelDemo/COPYING`).
