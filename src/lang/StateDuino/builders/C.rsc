module lang::StateDuino::builders::C

import IO;
import List;
import String;

import lang::StateDuino::ast::Full;
import lang::StateDuino::ast::Main;
import lang::StateDuino::transformations::Simplify;
import lang::StateDuino::semantics::Checker;

public void writeStateMachine(loc directory, loc coordinator) {
	<coor, machines> = loadFullStateMachine(coordinator);
	checkForErrors(machines);
	machines = {simplify(m) | m <- machines};
	for (m <- machines) {
		writeStateMachine(directory, m);	
	}
	//writeCoordinator(directory, coor);
}

private void checkForErrors(set[StateMachine] machines) {
	set[Message] errors = {};
	for (sm <- machines) {
		errors += performFullCheck(sm);
	}
	if (errors != {}) {
		throw "One or more errors in the state machines: <errors>";
	}
}

private void writeStateMachine(loc directory, StateMachine sm) {
	loc hFile = directory[file="<sm.name.name>.h"];
	loc cFile = directory[file="<sm.name.name>.cpp"];
	loc hSMFile = directory[file="_SM<sm.name.name>.h"];
	loc cSMFile = directory[file="_SM<sm.name.name>.cpp"];
	writeCallbackHeader(hFile, sm);
	/*
	if (!exists(cFile)) {
		writeDefaultCallback(cFile, sm);	
	}
	writeStateMachineHeadere(hSMFile, sm);
	writeStateMachineImplementation(cSMFile, sm);
	*/
}

private str getParam(param(str t, str n)) = "<t> <n>";

private str getParams(parameterized(_, [Parameter first, list[Parameter] rest])) {
	 params = (getParam(first.name) | it + ", " + getParam(m.name) | m <- rest);
	
}

private default str getParams(StateMachineIdentifier smi) = "";

private void writeCallbackHeader(loc f, StateMachine sm) {
	str params = getParams(sm);
	writeFile(f, "#IFNDEF <toUpperCase(sm.name.name)>_H
	'#DEFINE <toUpperCase(sm.name.name)>_H
	'<for(ac <- sort([ *{ a.name | /list[Action] a <- sm, size(a) > 1}])) {>
		'void <ac>(<params>);
	'<}>
	'<for(cn <- sort([ *{ con | /single(str con) <- sm}])) { >
		'uint8_t c_<cn>(<params>);
	'<}>
	'#ENDIF
	");
}