/// @desc Prefix Trie
function prefix_trie() constructor
{
	/// @desc Trie Node (Internal Use Only)
	/// @param {String} [_affix]=""
	/// @ignore	
	static node = function(_affix = "") constructor
	{
		isEndOfword = false;
		prefix = _affix;
		children = {};
	}
	
	__total_nodes = 1;
	root = new node();
	
	/// @desc Insert word into the trie
	/// @param {string} _word
	static insert = function(_word)
	{
		var _node = self.root;
		var _word_length = string_length(_word);
		var i = 1;
		
		var _key_char, _fragment_length, _fragment, _new_node, _prefix, _prefix_length, _shared_prefix_length, _min_length, _new_prefix, _new_child;
        while (i <= _word_length)
		{
            _key_char = string_char_at(_word, i);
			__TRIE_SLICE_FRAGMENT_FROM_END_OF_WORD
			
			//If no matching key exists, the remaining word fragment can be added as a child node
            if (!struct_exists(_node.children, _key_char))
			{
				__total_nodes++;
                _new_node = new node(_fragment);
                _new_node.isEndOfword = true;
                _node.children[$ _key_char] = _new_node;
                return self;
            }

            _node = _node.children[$ _key_char];
			__TRIE_GET_SHARED_PREFIX_LENGTH
			
			//March index forward by the shared number of characters
            i += _shared_prefix_length;
			
			//Split
            if (_shared_prefix_length < _prefix_length)
			{
				__total_nodes++;
				
				//Copy node properties to new child
				_new_prefix = string_copy(_prefix, _shared_prefix_length + 1, _prefix_length - _shared_prefix_length);
                _new_child = new node(_new_prefix);
				
                _new_child.isEndOfword = _node.isEndOfword;
                _new_child.children = _node.children;
				
				//Assign new properties for this node
                _node.prefix = string_copy(_prefix, 1, _shared_prefix_length);
				_node.children = {};
				_node.children[$ string_char_at(_new_prefix, 1)] = _new_child;
                _node.isEndOfword = i + 1 == _word_length;
            }
        }
		return self;
	}
	
	/// @desc Get an array of words beginning with the search string (results may need to be sorted)
	/// @param {String} _word Search String
	/// @param {Real} [_max_entries]
	/// @return {Array<String>} results
	static get_completions = function(_word, _max_entries = -1)
	{
		var _output = [];
		if(_word == "")
		{
			// Feather disable once GM1045
			return _output; //Empty string (Feather really doesn't like the idea of empty arrays when a type is defined)
		}
		
		var _node = self.root;
		var _word_length = string_length(_word);
		var _starting_prefix = "";
		
		//Match search string fragment to a node
		var _shared_prefix_length, _min_length, _fragment_length, _fragment, _prefix, _prefix_length;
		for(var i = 1; i <= _word_length; i += _shared_prefix_length)
		{
		    var _key_char = string_char_at(_word, i);
			
			//No matching node
		    if (!struct_exists(_node.children, _key_char))
			{
		        // Feather disable once GM1045
		        return _output;
		    }
			
		    _node = _node.children[$ _key_char];
			__TRIE_SLICE_FRAGMENT_FROM_END_OF_WORD
			__TRIE_GET_SHARED_PREFIX_LENGTH

			_starting_prefix += _prefix;
		}
		
		//Get completions by recursively searching the child nodes for ones marked as ends of words
		self.__recursive_search(_node, _starting_prefix, _output, _max_entries);
		
        // Feather disable once GM1045
        return _output;
	}
	
	/// @desc Check a word exists in the trie
	/// @param {string} _word
	/// @return {Bool} Word Exists
	static word_exists = function(_word)
	{
		if(_word == "") {return false;}
		
		var _node = self.root;
		var _word_length = string_length(_word);
		var _key_char, _shared_prefix_length, _prefix, _prefix_length, _min_length, _fragment, _fragment_length;
		for(var i = 1; i <= _word_length; i += _shared_prefix_length)
		{
		    _key_char = string_char_at(_word, i);
			
			//No matching node
		    if (!struct_exists(_node.children, _key_char))
			{
		        return false;
		    }
			
		    _node = _node.children[$ _key_char];
			__TRIE_SLICE_FRAGMENT_FROM_END_OF_WORD
			__TRIE_GET_SHARED_PREFIX_LENGTH
		    
			//Matching prefix isn't the same size as the word
			if (_shared_prefix_length != _prefix_length)
			{
		        return false;
		    }
		}
        return _node.isEndOfword;
	}
		
	/// @desc Delete a word from the trie
	/// @param {string} _word
	static word_delete = function(_word)
	{
		if(_word == "") {exit;}
		
		
		var _node = self.root;
		var _prev_node = -1;
		var _word_length = string_length(_word);
		
		var _key_char, _shared_prefix_length, _prefix, _prefix_length, _min_length, _fragment, _fragment_length;
		//Find the node matching to the end of the word
		for(var i = 1; i <= _word_length; i += _shared_prefix_length)
		{
		    _key_char = string_char_at(_word, i);
			
			//No matching node
		    if (!struct_exists(_node.children, _key_char))
			{
		        exit;
		    }
			
			_prev_node = _node;
		    _node = _node.children[$ _key_char];
			__TRIE_SLICE_FRAGMENT_FROM_END_OF_WORD
			__TRIE_GET_SHARED_PREFIX_LENGTH
			
			//Matching prefix isn't the same size as the word
			if (_shared_prefix_length != _prefix_length)
			{
		        exit;
		    }
		}
		
		//If we've hit the target word
        if(_node.isEndOfword)
		{
			_node.isEndOfword = false;
			var _child_count = struct_names_count(_node.children);
			
			//If this node has multiple children then it needs to continue to exist
			if(_child_count > 1)
			{
				exit;
			}
			
			__total_nodes--;
			
			//Node has no children and can simply be deleted from its parent node
			if (_child_count == 0)
			{
				struct_remove(_prev_node.children, _key_char);
				delete _node;
				exit;
			}
			
			//If this node has an 'only child', the two can be merged together
			var _child = _node.children[$ struct_get_names(_node.children)[0]];
			_node.children =	_child.children;
			_node.prefix +=		_child.prefix;
			_node.isEndOfword = _child.isEndOfword;
			delete _child;
		}
	}
	/// @desc Function get_node_count
	/// @return {Real} Count
	static get_node_count = function()
	{
		return __total_nodes;
	}
	
	/// @ignore
	static __recursive_search = function(_node, _current_prefix, _output, _max_entries)
	{
		if(_max_entries != -1 && array_length(_output) >= _max_entries)
		{
			return true;
		}
			
        if (_node.isEndOfword)
		{
			array_push(_output, _current_prefix);
        }
		
		var _names = struct_get_names(_node.children);
        for (var i = array_length(_names) - 1; i >= 0; --i)
		{
			var _child_node = _node.children[$ _names[i]];
            if(self.__recursive_search(_child_node, _current_prefix + _child_node.prefix, _output, _max_entries))
			{
				return true;
			}
        }
		return false;
    }
}

#region Inline Macro Code (saves a meaningful amount of performance vs using functions)
//Slice the current fragment from the end of the word, starting from i
#macro __TRIE_SLICE_FRAGMENT_FROM_END_OF_WORD { \
	_fragment_length = _word_length - (i - 1); \
	_fragment = string_copy(_word, i, _fragment_length);}

//March along both prefix and fragment strings, comparing each character until we hit the shared length or a non-match, returning the (index - 1)
#macro __TRIE_GET_SHARED_PREFIX_LENGTH { \
	_prefix = _node.prefix; \
	_prefix_length = string_length(_prefix); \
	\
	_min_length = min(_fragment_length, _prefix_length); \
	_shared_prefix_length = 1; \
	while (_shared_prefix_length <= _min_length && string_char_at(_fragment, _shared_prefix_length) == string_char_at(_prefix, _shared_prefix_length)) \
	{ \
		_shared_prefix_length++; \
	} \
	_shared_prefix_length--;}
#endregion