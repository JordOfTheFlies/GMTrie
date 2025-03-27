/// @desc Fill trie from text file dictionary
/// @param {Struct.prefix_trie} _trie
/// @param {String} _fname Text File
function trie_load_dictionary(_trie, _fname) {
	if !(is_struct(_trie) && is_instanceof(_trie, prefix_trie)) {
		throw("Tried to load dictionary into invalid trie!");
	}
	
	var _result = {
					load_succeeded: false,
					total_words: 0,
					total_characters: 0
					};
	
	var _time = get_timer();
	var _count = 0;
	var _chars = 0;

	//Default is far beyond the number of lines anyone should ever try to load
	var _line_limit = 1_000_000;
	
	if(file_exists(_fname)) {
		var _file = file_text_open_read(_fname);
		
		if(_file == -1) {
			show_debug_message("Error opening file!");
			return _result;
		}
		
		var l;
		while (!file_text_eof(_file)) {
			_count++;
			l = file_text_read_string(_file);
			_chars += string_length(l);
			_trie.insert(l);
		    file_text_readln(_file);
		}
		file_text_close(_file);
		
		_result.load_succeeded		= true;
		_result.total_words			= _count;
		_result.total_characters	= _chars;
		
		//Print debug info
		_time = (get_timer() - _time) / 1000;
		_fname = filename_name(_fname);
		var _avg = _count / _chars;
		
		show_debug_message($"Loaded '{_fname}' in {_time} ms, {_count} lines & {_chars} chars (avg {_avg} per word)");
	}
	else
	{
		show_debug_message($"File '{_fname}' does not exist!");
	}
	
	return _result;
}