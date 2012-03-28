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
		errors += performStructuralCheck(sm);
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
	
	if (!exists(cFile)) {
		writeDefaultCallback(cFile, sm);	
	}
	/*
	writeStateMachineHeadere(hSMFile, sm);
	writeStateMachineImplementation(cSMFile, sm);
	*/
}

private str getParam(param(str t, str n)) = "<t> <n>";

private str getParams(parameterized(_, [Parameter first, list[Parameter] rest])) {
	 return (getParam(first) | it + ", " + getParam(m) | m <- rest);
}

private default str getParams(StateMachineIdentifier smi) = "";

private str getConditionName(str con) = replaceAll(con, "?","");

private void writeCallbackHeader(loc f, StateMachine sm) {
	str params = getParams(sm.name);
	writeFile(f, "#IFNDEF <toUpperCase(sm.name.name)>_H
	'#DEFINE <toUpperCase(sm.name.name)>_H
	'/***************************************
	'** This file is generated, do not edit! 
	'** You can edit SharedState.h or <sm.name.name>.cpp
	'****************************************/
	'#include \"SharedState.h\"
	'#include \<stdint.h\>
	'	
	'void initialize(SharedState state, <params>);
	'
	'<for(action(ac) <- sort([ *{ *as | /[list[Action] as, _] <- sm}])) {>
		'void <ac>(<params>);
	'<}>
	'<for(cn <- sort([ *{ con | /single(str con) <- sm}])) { >
		'uint8_t _con_<getConditionName(cn)>(<params>);
	'<}>
	'#ENDIF
	");
}


private void writeDefaultCallback(loc f, StateMachine sm) {
	str params = getParams(sm.name);
	writeFile(f, "#include \"<sm.name.name>.h\"
	'	
	'void initialize(SharedState state, <params>) {
	'
	'}
	'
	'<for(action(ac) <- sort([ *{ *as | /[list[Action] as, _] <- sm}])) {>
		'void <ac>(<params>) {
		'
		'}
	'<}>
	'<for(cn <- sort([ *{ con | /single(str con) <- sm}])) { >
		'uint8_t _con_<getConditionName(cn)>(<params>) {
		'\treturn 1;
		'}
	'<}>
	");
}
