Basic Compressed Prefix Trie for Gamemaker Studio 2  

Includes example project + scripts to load dictionaries from a text file in one go or deferred over several steps.  
Free to use, just throw me a credit if you feel like it.

Useful for autocompleting words from a partial beginning. Reasonably fast, and acceptable memory use. Details at the end of this README.  
GM adds quite a bit of overhead though, so what should probably be 70 MB of RAM ends up as more like 700 MB (for ~500K dictionaries).  
If you just need to confirm a word is in a dictionary, use a struct/ds_map instead as that will be faster and use a fraction of the memory.  
No spelling correction, as I neither have the patience right now to write a fuzzy sort algorithm , nor faith it will run fast enough to be worth it.

An example project shows how to use it for a basic autocomplete.
Only the prefix_trie file is needed for general use and the test object/room should be deleted.  
The project uses a public domain 5000-word list from: https://github.com/MichaelWehar/Public-Domain-Word-Lists

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Performance Expectations for 'prefix_trie':

	The below measurements were recorded on a PC from 2015 using an i5 4690K (3.50GHz, 4 cores, 4 threads).
	Expect newer gaming PCs to load faster, non-gaming PCs to potentially load a little slower, and mobile devices to differ significantly.
	Words were loaded from dictionaries stored in .txt files using the file_text_ functions, adding some minor overhead to load times (i.e. loading the 100K file took 540.86 ms).
    
  	The average number of nodes per word will increase as the trie becomes less sparse, logically starting at 1 node per word and eventually approaching 1 node per character.
	Memory usage increases by about 1 MB per thousand nodes generated.
	
	(Small) 200 word dictionary (2 KB):
		Represents a practical application for auto-completing game-specific terms.
		
		Load time (YYC):	4.42 ms
		Load time (VM):		3.53 ms (Yes, this repeatedly appeared to load slightly faster on VM)
		Memory Increase:	n/a (Negligible impact too small to accurately measure)
		Node Count:				247
		
		Conclusion: The 3.82 ms load time is well below the 16 ms frametime target needed to hit 60 fps, so represents an unnoticable delay even if not done ahead of time
	
	
	(Large) 100,000 word dictionary (~1.07 MB):
		Represents a game using an extensive list of real words. For reference, the dictionary used for the game Cryptkeeper is only about 79K words.
		
		Load time (YYC):	1,422 ms (1.4 seconds)
		Load time (VM):		2,404 ms (2.4 seconds)
		Memory Increase:	135 MB
		Node Count:				127,949
		
		Conclusion: Now seeing a noticable hitch, but not too much of an issue if loading is done once at the start of game
	
	
	(Huge) 466,550 word dictionary (4.63 MB):
		The closest in word count to the The Oxford English Dictionary 519,834 headwords that I could find.
		
		Load time (YYC):	5,317 ms (5.3 seconds, down to ~3.4 seconds when tested on an Ryzen 5800x3D)
		Load time (VM):		8,544 ms (8.5 seconds)
		Memory Increase:	680 MB
		Node Count:				608,382
		
		Conclusion: If loading a dictionary this large, make sure your target platform can afford the game to use a gigabyte of RAM
		I'd advice loading the dictionary in chunks (i.e. 100 lines at a time) over several steps, to avoid completely locking up the game for several seconds
		
			
Testing trie_load_dictionary_deferred() vs trie_load_dictionary() Load Times (VM):

	(Medium) 5,000 word dictionary (39 KB):
		Normal Load (All at once):						73.47ms
										
		500 Lines Per Step (10 Step Total):		174.23
		Speed penalty vs Normal:							2.37x slower
										
		1000 Lines Per Step (5 Step Total):		98.38 ms
		Speed penalty vs Normal:							1.33x slower
										
	(Huge) 466,550 word dictionary (4.63 MB):
		Normal Load (All at once):						8,523.35 ms

		500 Lines Per Step (932 Step Total):	15,761.92 ms
		Speed penalty vs Normal:							1.59x slower

		1000 Lines Per Step (467 Step Total):	9,877.95 ms
		Speed penalty vs Normal:							1.15x slower

	Conclusion:
		Use the highest line-per-step count possible for the lowest load times.
		If you can afford to just have a delay, that's idea for all but the largest of dictionaries.
		Speed penalty diminishes relative to the size of the dictionaries being loaded.
		500 lines per step stay above 60fps, 1000 may dip into the 40s but is still an interactive framerate.
