Loop pedal
==========

* python + poll for gpios
* chuck + usb soundcard for sound 
* alsa since jackd would not work

Run
---

  chuck --dac:2 lsp.ck & python watch_input.py
