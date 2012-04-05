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
	writeStateMachineHeader(hSMFile, sm);
	writeStateMachineImplementation(cSMFile, sm);
	writeCallbackHeader(hFile, sm);
	if (!exists(cFile)) {
		writeDefaultCallback(cFile, sm);	
	}
}

private str getParam(param(str t, str n)) = "<t> <n>";

private str getParams(parameterized(_, [Parameter first, list[Parameter] rest])) {
	 return (getParam(first) | it + ", " + getParam(m) | m <- rest);
}

private default str getParams(StateMachineIdentifier smi) = "";

private str getConditionName(str con) = replaceAll(con, "?","");

private void writeCallbackHeader(loc f, StateMachine sm) {
	str params = getParams(sm.name);
	str paramsNotFirst = params == "" ? "" : ", " + params;
	writeFile(f, "#IFNDEF <toUpperCase(sm.name.name)>_H
	'#DEFINE <toUpperCase(sm.name.name)>_H
	'/***************************************
	'** This file is generated, do not edit! 
	'** You can edit SharedState.h or <sm.name.name>.cpp
	'****************************************/
	'#include \"SharedState.h\"
	'#include \<stdint.h\>
	'#ifdef __cplusplus
	'extern \"C\"{
	'#endif	
	
	'void initialize(SharedState state <paramsNotFirst>);
	'
	'<for(action(ac) <- sort([ *{ *as | /[list[Action] as, _] <- sm}])) {>
		'void <ac>(<params>);
	'<}>
	'<for(cn <- sort([ *{ con | /single(str con) <- sm}])) { >
		'uint8_t _con_<getConditionName(cn)>(<params>);
	'<}>
	
	'#ifdef __cplusplus
	'}
	'#endif
	'#ENDIF
	");
}


private void writeDefaultCallback(loc f, StateMachine sm) {
	str params = getParams(sm.name);
	str paramsNotFirst = params == "" ? "" : ", " + params;
	writeFile(f, "#include \"<sm.name.name>.h\"
	'	
	'void initialize(SharedState state <paramsNotFirst>) {
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

private void writeStateMachineHeader(loc f, StateMachine sm) {
	str params = getParams(sm.name);
	str paramsNotFirst = params == "" ? "" : ", " + params;
	writeFile(f, "#IFNDEF _SM<toUpperCase(sm.name.name)>_H
	'#DEFINE _SM<toUpperCase(sm.name.name)>_H
	'/***************************************
	'** This file is generated, do not edit! 
	'** You can edit SharedState.h or <sm.name.name>.cpp
	'****************************************/
	'#include \"SharedState.h\"
	'#include \<stdint.h\>
	'#ifdef __cplusplus
	'extern \"C\"{
	'#endif	
	
	'void(*)() <sm.name.name>_initialize(SharedState state <paramsNotFirst>);
	'void(*)()  <sm.name.name>_takeStep(void(*)() sm <paramsNotFirst>);
	'uint8_t <sm.name.name>_isSleepableStep(void(*)() sm);
	
	'#ifdef __cplusplus
	'}
	'#endif
	'#ENDIF
	");
}
private str getParamInvoke(param(str t, str n)) = "<n>";

private str getParamsInvoke(parameterized(_, [Parameter first, list[Parameter] rest])) {
	 return (getParamInvoke(first) | it + ", " + getParam(m) | m <- rest);
}

private default str getParamsInvoke(StateMachineIdentifier smi) = "";

private str getParamTypes(param(str t, str n)) = "<t>";

private str getParamsTypes(parameterized(_, [Parameter first, list[Parameter] rest])) {
	 return (getParamTypes(first) | it + ", " + getParam(m) | m <- rest);
}

private default str getParamsTypes(StateMachineIdentifier smi) = "";

private str getForkNameInvoke(action(str nm)) = "_<nm>";
private str getForkNameInvoke(name(str nm)) = "_<nm>";


private void writeStateMachineImplementation(loc f, StateMachine sm) {
	str params = getParams(sm.name);
	str paramsNotFirst = params == "" ? "" : ", " + params;
	str paramsInvoke = getParamsInvoke(sm.name);
	str paramsInvokeNotFirst = paramsInvoke == "" ? "" : ", " + paramsInvoke;
	writeFile(f, "#include \"_SM<sm.name.name>.h\"
	'/***************************************
	'** This file is generated, do not edit! 
	'** You can edit SharedState.h or <sm.name.name>.cpp
	'****************************************/
	'#include \"<sm.name.name>.h\"
	'	
	'void* <sm.name.name>_initialize(SharedState state <paramsNotFirst>) {
	'	initialize(state, <paramsInvokeNotFirst>);
	'	return reinterpret_cast\<void*\>(<getForkNameInvoke(sm.startFork)>); 
	'}
	'
	'void* <sm.name.name>_takeStep(void* sm <paramsNotFirst>) {
	'	return reinterpret_cast\<void* (*)(<getParamsTypes(sm.name)>)\>(sm)(<paramsInvoke>);	
	'}
	'
	'uint8_t <sm.name.name>_isSleepableStep(void* sm) {
	'	<for(fork([_*, sleepable(), _*], nm, _, _) <- sm.definitions) {>
	'	if (sm == reinterpret_cast\<void*\>(<getForkNameInvoke(nm)>)) {
	'		return 1;
	'	} 
	'	<}>
	'	return 0;
	'}
	");
}