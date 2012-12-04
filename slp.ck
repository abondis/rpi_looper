// create our OSC receiver
OscRecv orec;
// port 6449
6449 => orec.port;
// start listening (launch thread)
orec.listen();

//a simple signal path
adc => LiSa saveme => dac;

//gotta tell LiSa how much memory to allocate
10::second => saveme.duration;

saveme.recRamp(200::ms);

//var to know if recoding or playing
"paused" => string state;
time start_time;
dur loop_duration;
function void start_recording() {
    //start recording
    1 => saveme.record;
    // start counting for the loop duration
    now => start_time;
    "recording" => state;
}
function void stop_recording() {
    //stop recording
    0 => saveme.record;
    // save loop duration
    now - start_time => loop_duration;
    <<< "loop_duration:", loop_duration>>>;
    // keep duration ?
    saveme.loopEnd(loop_duration);
    "paused" => state;
}

function void start_stop_recording()
{ 
    // create an address in the receiver 
    // and store it in a new variable.
    orec.event("/record") @=> OscEvent record_event; 

    while ( true )
    { 
        record_event => now; // wait for events to arrive.

        // grab the next message from the queue. 
        while( record_event.nextMsg() != 0 )
        { 
            <<< "state", state >>>;
            if (state == "playing") {
                stop_playing();
            }
            if (state == "paused") {
                <<< "recoding" >>>;
                start_recording();
            }
            else {
                if (state == "recording"){
                <<< "stopped recording" >>>;
                    stop_recording();
                    start_playing();
                }
            }
        }
    }
}
function void stop_playing() {
    <<< "stop recording">>>;
    "paused" => state;
    0 => saveme.loop;
    0 => saveme.play;
}
function void start_playing() {
    <<< "start playing">>>;
    "playing" => state;
    1 => saveme.loop;
    1 => saveme.play;
}

function void play_loop()
{ 
    orec.event("/play") @=> OscEvent play_event; 
    while ( true )
    {
        play_event => now; // wait for events to arrive.

        // grab the next message from the queue. 
        while( play_event.nextMsg() != 0 )
        {
            <<< "play event, state:", state >>>;
            if (state == "recording") {
                stop_recording();
            }
            if (state == "playing") {
                <<< "stop playing">>>;
                stop_playing();
            }
            else {
                if (state == "paused") {
                    start_playing();
                }
            }
        }
    }
}
spork ~ start_stop_recording();
spork ~ play_loop();

while (true) {
    10::second => now;
}

