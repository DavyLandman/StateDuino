module lang::StateDuino::transformations::Simplify

import List;
import Map;
import IO;
import Relation;
import Set;
import lang::StateDuino::ast::Main;

public StateMachine simplify(StateMachine complex) {
	StateMachine result = complex;
	result = removeUnnamedForks(result);
	result = removeSelfReferences(result);
	result = unnestForks(result);
	result = inlineChains(result);
	return result;
}
private StateMachine removeUnnamedForks(StateMachine sm) {
	int newNameCounter = 0;
	return visit(sm) {
		case f:namelessFork(types, pre, paths) : {
			Name newName = name("_nameless<newNameCounter>")[@location = f@location];
			newNameCounter += 1;
			insert fork(types, newName , pre, paths)[@location = f@location];
		}
	};
}

private StateMachine removeSelfReferences(StateMachine sm) {
	list[Definition] newDefinitions = [];
	for (d <- sm.definitions) {
		switch(d) {
			case chain(_,_) : newDefinitions += [d];
			case fork(_,_,_,_) : newDefinitions += [removeSelfReferences(d)];
			default : throw "Case <d> forgotten";
		}	
	}
	return sm[definitions = newDefinitions];
}

private Definition removeSelfReferences(f:fork(_,nm, _, paths)) {
	list[ConditionalPath] newPaths = [];
	for (p <- paths) {
		newPaths += [p[actions=removeSelfReferences(p.actions, nm.name)]];
	}
	return f[paths = newPaths];
}
private list[Action] removeSelfReferences(list[Action] acs, str nm) {
	list[Action] newActions = [];
	for (a <- acs) {
		switch(a) {
			case action("self") : newActions += [a[name=nm]];
			case action(_) : newActions += [a];
			case definition(d) : newActions += [a[definition= removeSelfReferences(d)]];
			default : throw "Case <a> forgotten";
		}	
	}
	return newActions;
}

private default Definition removeSelfReferences(Definition d) {
	throw "Not supported definition";
}

private StateMachine inlineChains(StateMachine sm) {
	map[str, list[Action]] chainActions = ( m : p | chain(name(m), p) <- sm.definitions);
	list[Definition] newDefinitions = [];
	
	list[Action] inlineChains(list[Action] acs) {
		result = acs;
		solve(result) {
			if ([list[Action] prev, Action tl] := result) {
				result = prev + (chainActions[tl.name]? [tl]);
			}
		}
		return result;
	}
	
	for (f:fork(_,_,pre,paths) <- sm.definitions) {
		newPre = inlineChains(pre);
		newPaths = [];
		for (p <- paths) {
			newPaths += [p[actions = inlineChains(p.actions)]];				
		}
		newDefinitions += [f[preActions = newPre][paths=newPaths]];
	}
	return sm[definitions = newDefinitions];
}

private StateMachine unnestForks(StateMachine sm) {
	list[Definition] newDefinitions = [];
	set[str] usedNames = {nm | fork(_, name(nm), _, _) <- sm.definitions}
		+ {nm | chain(name(nm), _) <- sm.definitions};
	for (d <- sm.definitions) {
		<newDefs, newUsedNames> = unnestForks(d, (), usedNames);	
		newDefinitions += newDefs;	
		usedNames += newUsedNames;
	}
	return sm[definitions = newDefinitions];
}

private tuple[list[Definition], set[str]] unnestForks(c:chain(_,acs), map[str, str] renames, set[str] usedNames) {
	<newAcs, newDefinitions, newUsedNames> = unnestForks(acs, (), usedNames);
	return <[c[actions=newAcs], *newDefinitions], usedNames + newUsedNames>;
}
private tuple[list[Definition], set[str]] unnestForks(f:fork(_,_,_, paths), map[str, str] renames, set[str] usedNames) {
	list[ConditionalPath] newPaths = [];
	list[Definition] newDefinitions = [];
	for (p <- paths) {
		<newAcs, newDefs, newUsedNames> = unnestForks(p.actions, renames, usedNames);
		usedNames += newUsedNames;
		newPaths += [p[actions = newAcs]];
		newDefinitions += newDefs;
	}
	return <[f[paths = newPaths], *newDefinitions], usedNames>;
}

private tuple[list[Action], list[Definition], set[str] ] unnestForks(list[Action] acs, map[str, str] renames, set[str] usedNames) {
	list[Action] newActions = [];
	list[Definition] newDefinitions = [];
	for (a <- acs) {
		switch(a) {
			case action(nm) : {
				if (renames[nm]?) {
					newActions += [a[name=renames[nm]]];
				}
				else {
					newActions += [a];	
				}
			}
			case definition(d) : {
				str oldName = d.name.name;
				str newName = (oldName in usedNames) ? "<oldName>_<d.name@location.offset>" : oldName;
				usedNames += {newName};
				newD = d[name = d.name[name=newName]];
				<newDefs, newUsedNames> = unnestForks(newD,	renames + (oldName : newName), usedNames);
				newDefinitions += newDefs;
				usedNames += newUsedNames;
				newActions += [action(newName)[@location = d@location]];
			}
			default : throw "unexpected case?";
		}
	}	
	return <newActions, newDefinitions, usedNames>;
}