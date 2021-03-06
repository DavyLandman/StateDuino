module lang::StateDuino::cst::Parse

import lang::StateDuino::cst::Syntax;
import ParseTree;
import util::IDE;
import util::SyntaxHighlightingTemplates;

public start[StateMachine] parseStateMachine(str stateDuinoString) = 
	parse(#start[StateMachine], stateDuinoString);


public start[StateMachine] parseStateMachine(loc stateDuinoFile) = 
	parse(#start[StateMachine], stateDuinoFile); 
	
public start[StateMachine] parseStateMachine(str stateDuinoString, loc stateDuinoFile) = 
	parse(#start[StateMachine], stateDuinoString, stateDuinoFile); 
	
public start[Coordinator] parseCoordinator(str stateDuinoString) = 
	parse(#start[Coordinator], stateDuinoString);


public start[Coordinator] parseCoordinator(loc stateDuinoFile) = 
	parse(#start[Coordinator], stateDuinoFile); 
	
public start[Coordinator] parseCoordinator(str stateDuinoString, loc stateDuinoFile) = 
	parse(#start[Coordinator], stateDuinoString, stateDuinoFile); 
	
	
public void registerIDE() {
	registerLanguage("The StateDuino language", "sdo", start[StateMachine] (str s, loc l) {
		return parseStateMachine(s, l); 
	});
	registerContributions("The StateDuino language", {getSolarizedLightCategories()});
}