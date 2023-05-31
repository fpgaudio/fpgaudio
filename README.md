# fpgaudio

This project is a demo of a Leap Media Controller-modulated FPGA-driven
synthesizer.

## Building and Running

To get the source code, please run something like:

```bash
git clone git@github.com:fpgaudio/fpgaudio.git
cd fpgaudio
quartus fpgaudio.qpf
```

You can build within quartus and flash as normal.

**Note: Mainline is not stable. There are no guarantees this will build on
`main`. Use a frozen tag.**

## Navigating The Repository

This repository follows a `git` submodule-based structure. `git` is a core part
of this repository and without it the full source code is not guaranteed to be
available.

The following dependency tree should explain what each submodule does and is
responsible for.

```
/ - The root of the `fpgaudio` program. This is the top-level.
subprojects/
├─ midas/ - The simplified `MIDI` decoder in SV.
├─ midi_module/ - The extended `MIDI` decoder in SV.
├─ orpheus-vlg/ - The main sound synthesis engine in SV.
│  ├─ cordic/ - An implementation of CORDIC in SV.
│  ├─ orpheus/ - The main sound synthesis engine in CXX.
├─ fpga-lmc/ - A decoder and USART serializer for the LMC in C and CXX.
```

For detailed description of each of the components, please see the `README`
document of every component.
