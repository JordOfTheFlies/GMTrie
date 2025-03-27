/// @description Check for input
if(autocomplete_input != "" && autocomplete_input != autocomplete_input_last) {
	autocomplete_input_last = autocomplete_input;
	do_autocomplete();
}