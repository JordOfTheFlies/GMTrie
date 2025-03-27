/// @desc Fill trie from text file dictionary over multiple steps then execute a callback
/// @param {Struct.prefix_trie} _trie
/// @param {String} _fname Text File
/// @param {Real} [_lines_per_step] Lines to add per step
/// @param {Function, Undefined} [_callback]
function trie_load_dictionary_deferred(_trie, _fname, _lines_per_step = 500, _callback = undefined) {
	if !(is_struct(_trie) && is_instanceof(_trie, prefix_trie)) {
		throw("Tried to load dictionary into invalid trie!");
	}
	
	var _data = {
					trie: _trie,
					lines_per_step: _lines_per_step,
					callback: _callback,
					
					file: undefined,
					timesource: undefined,
					time_started: get_timer(),
					
					gc_prev_target: gc_get_target_frame_time(),
					
					results: {
								fname: _fname,
					
								load_succeeded: false,
								total_words: 0,
								total_characters: 0,
					
								time_taken: 0,
								steps_taken: 0,
							},
				};
	
	// Feather disable once GM2043
	var _ts = time_source_create(time_source_game, 1, time_source_units_frames, __on_step, [_data], -1, time_source_expire_nearest);
	_data.timesource = _ts;
	
	//Tell garbage collector to be much more active while loading to avoid being swamped by GC afterwards
	gc_target_frame_time(1_000_000 / 100);
	
	//Open file
	if(file_exists(_fname)) {
		_data.file = file_text_open_read(_fname);
		
		if(_data.file == -1) {
			show_debug_message("Error opening file!");
		}
		
		time_source_start(_ts);
	}
	else
	{
		show_debug_message($"File '{_fname}' does not exist!");
	}
	
	static __on_step = function(_data) {
		var _count = 0;
		var _chars = 0;
		var _steps = _data.lines_per_step;
		var _trie = _data.trie;
		var _file = _data.file;
		var _succeeded = true;
		var l;
		
		try {
			while (!file_text_eof(_file) && _count <= _steps) {
				_count++;
				l = file_text_read_string(_file);
				_chars += string_length(l);
				_trie.insert(l);
			    file_text_readln(_file);
			}
		}
		catch( _exception) {
			_succeeded = false; //Probably a poor solution, but hard to guarantee a file will stay valid
		}
		
		var _results = _data.results;
		_results.total_words		+= _count;
		_results.total_characters	+= _chars;
		
		if(file_text_eof(_file)) {
			trie_load_dictionary_deferred.__on_complete(_data, _succeeded);
		}
	}
	
	static __on_complete = function(_data, _load_succeeded) {
		try {
			file_text_close(_data.file);
		}
		var _ts = _data.timesource;
		var _reps = time_source_get_reps_completed(_ts)
		time_source_stop(_ts);
		time_source_destroy(_ts);
		gc_target_frame_time(_data.gc_prev_target);
		
		var _time = (get_timer() - _data.time_started) / 1000;
		
		//Print debug info
		var _results = _data.results;
		var _fname = filename_name(_results.fname);
		var _avg = _results.total_words / _results.total_characters;
		_results._load_succeeded	= true;
		_results.time_taken			= _time;
		_results.steps_taken		= _reps;
		
		show_debug_message($"Loaded '{_fname}' in {_time} ms / {_reps} steps, {_results.total_words} lines & {_results.total_characters} chars (avg {_avg} per word)");
		
		if(!is_undefined(_data.callback)) {
			_data.callback(_results);
		}
	}
}