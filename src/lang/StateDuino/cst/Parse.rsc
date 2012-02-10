module lang::StateDuino::cst::Parse

import lang::StateDuino::cst::stateduino;
import ParseTree;
import util::IDE;

public start[StateMachine] parseStateMachine(str stateDuinoString) = 
	parse(#start[StateMachine], stateDuinoString);


public start[StateMachine] parseStateMachine(loc stateDuinoFile) = 
	parse(#start[StateMachine], stateDuinoFile); 
	
public void registerIDE() {
	registerLanguage("The StateDuino language", "sdo", start[StateMachine] (str s, loc l) {
		return parse(#start[StateMachine], s, l); 
	});
}