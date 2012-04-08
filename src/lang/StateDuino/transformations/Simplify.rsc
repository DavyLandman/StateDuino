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

private StateMachine inlineChains(StateMachine complex) {
	map[str, list[Action]] chainActions = ( m : p | chain(name(m), p) <- complex.definitions);
	solve(chainActions) {
		for (cn <- chainActions) {
			list[Action] acs = chainActions[cn];
			if (chainActions[last(acs).name]?) {
				// nested chain call;
				chainActions[cn] = prefix(acs) + chainActions[last(acs).name];
			}
		}
	}
	list[Action] replaceActions(list[Action] acts, set[str] nestedForkNames) {
		list[Action] result = [];
		for (a <- acts) {
			switch(a) {
				case action(nm): 
					if (!(nm in nestedForkNames) && chainActions[nm]?) {
						result += chainActions[nm];	
					}	
					else {
						result += [a];	
					}
				case d:definition(f) : {
					result += [d[definition = replaceActions(f, nestedForkNames + (f.name? ? {f.name.name} : {}))]];	
				}
			}
		}
		return result;
	};
	
	Definition replaceActions(Definition def, set[str] nestedForkNames) {
		list[ConditionalPath] newPaths = [];
		for (p <- def.paths) {
			newPaths += [p[actions = replaceActions(p.actions, nestedForkNames)]];
		}
		newPreActions = replaceActions(def.preActions, nestedForkNames);
		return def[paths= newPaths][preActions = newPreActions];
	};	
	// check forks inside chains
	for (cn <- chainActions) {
		chainActions[cn] = replaceActions(chainActions[cn], {cn});	
	}
	list[Definition] newDefinitions = [replaceActions(f, {}) | f:fork(_,_,_,_) <- complex.definitions];
	return complex[definitions = newDefinitions];
}

private StateMachine unnestForks(StateMachine sm) {
	list[Definition] newDefinitions = [];
	for (d <- sm.definitions) {
		newDefinitions += unnestForks(d, ());	
	}
	return sm[definitions = newDefinitions];
}

private list[Definition] unnestForks(c:chain(_,acs), map[str, str] renames) {
	<newAcs, newDefinitions> = unnestForks(acs, ());
	return [c[actions=newAcs], *newDefinitions];
}
private list[Definition] unnestForks(f:fork(_,_,_, paths), map[str, str] renames) {
	list[ConditionalPath] newPaths = [];
	list[Definition] newDefinitions = [];
	for (p <- paths) {
		<newAcs, newDefs> = unnestForks(p.actions, renames);
		newPaths += [p[actions = newAcs]];
		newDefinitions += newDefs;
	}
	return [f[paths = newPaths], *newDefinitions];
}

private tuple[list[Action], list[Definition]] unnestForks(list[Action] acs, map[str, str] renames) {
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
				str newName = "<oldName>_<d.name@location.offset>";
				newD = d[name = d.name[name=newName]];
				newDefinitions += unnestForks(newD,	renames + (oldName : newName));
				newActions += [action(newName)[@location = d@location]];
			}
			default : throw "unexpected case?";
		}
	}	
	return <newActions, newDefinitions>;
}