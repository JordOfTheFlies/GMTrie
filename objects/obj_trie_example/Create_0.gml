#macro TRIE_COMPLETIONS_TO_SHOW 16
show_debug_log(true);

trie = new prefix_trie();

autocomplete_input			= "";
autocomplete_input_last		= "";
autocomplete_result_text	= "";

trie_totals = "[Trie] Words: 0 | Chars: 0 | Nodes: 1";
memory_totals = "";

trie_load_deferred = false;
trie_is_loading = false;

#region Helper functions
get_memory = function() {
	var m = debug_event("DumpMemory", true);
	memory_totals = $"[Memory] totalUsed: {m.totalUsed / 1_000_000} MB | free: {m.free  / 1_000_000} MB | peakUsage: {m.peakUsage  / 1_000_000} MB";
}
call_later(10, time_source_units_frames, get_memory, true);

dict_load = function(_fname) {
	if(trie_is_loading) {
		exit;
	}
	//Throw away old trie and create new one
	delete trie;
	trie = new prefix_trie();
	
	if(trie_load_deferred) {
		trie_is_loading = true;
		trie_load_dictionary_deferred(trie, _fname, 1000, dict_load_finish);
	}
	else {
		var d = trie_load_dictionary(trie, _fname);
		dict_load_finish(d);
	}
}

dict_load_finish = function(d) {
	trie_totals = $"[Trie] Words: {d.total_words} | Chars: {d.total_characters} | Nodes: {trie.__total_nodes}";
	autocomplete_input_last = "";
	trie_is_loading = false;
	
	var _t = get_timer();
	gc_collect();
	_t = get_timer() - _t;
	show_debug_message($"Garbage Collection took {_t / 1000} ms");
}

dict_load_default = function() {
	dict_load("dictionary.txt");
}

dict_load_custom = function() {
	var _fname = get_open_filename("Text File|*.txt", "");
	if (_fname != "" && file_exists(_fname)) {
		
		//Get filesize
		var _buffer = buffer_load(_fname);
		var _filesize_megabytes = buffer_get_size(_buffer) / 1_000_000;
		buffer_delete(_buffer);
		
		if(_filesize_megabytes > 3) {
			//For massive files block loading
			if(_filesize_megabytes > 10) {
				show_debug_message("Dictionary >10 MB cannot be loaded (would use absurd amounts of RAM).");
				exit;
			}
			
			//Or force deferred loading
			show_debug_message($"Attempting to load {string_format(_filesize_megabytes, 1, 2)} MB dictionary -");
			show_debug_message("- Forcing deferred load to avoid freezing.");
			trie_load_deferred = true;
		}
		
	    dict_load(_fname);
	}
}

do_autocomplete = function() {
	var _time = get_timer();
	
	autocomplete_result_text = "";
    var _array = trie.get_completions(autocomplete_input, TRIE_COMPLETIONS_TO_SHOW);
	var _len = array_length(_array);
	for (var i = 0; i < _len; ++i) {
	    autocomplete_result_text += _array[i] + "\n";
	}
	
	_time = (get_timer() - _time) / 1000;
	show_debug_message($"Got {_len} completions in {_time} ms");
}
#endregion

//Debug controls
dbg_view("Prefix Trie Tester", true, 600, 50);

dbg_button("Load Default Wordlist", ref_create(self, "dict_load_default"), 200);
dbg_same_line();
dbg_button("Load Custom Wordlist", ref_create(self, "dict_load_custom"), 200);
dbg_checkbox(ref_create(self, "trie_load_deferred"), "Use Deferred File Loading:");
dbg_text(ref_create(self, "trie_totals"));
dbg_text(ref_create(self, "memory_totals"));

//Autocomplete input + results
dbg_text_separator("");
dbg_text_input(ref_create(self, "autocomplete_input"), "Autocomplete Entry:", "s");
dbg_text(ref_create(self, "autocomplete_result_text"));