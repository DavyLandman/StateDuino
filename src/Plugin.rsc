module Plugin

import util::IDE;
import util::SyntaxHighlightingTemplates;
import ParseTree;
import Message;
import Set;
import IO;

import lang::StateDuino::cst::Parse;
import lang::StateDuino::ast::Load;
import lang::StateDuino::semantics::Checker;

public void main() {
	registerLanguage("The StateDuino language", "sdo", parseStateMachine);
	registerAnnotator("The StateDuino language", Tree (Tree cst)
	{
		lang::StateDuino::ast::Main::StateMachine ast = getStateMachine(cst);
		set[Message] messages = fastCheck(ast);
		if (size(messages) > 0) {
			return cst[@messages = messages];
		}
		return cst;
	});
	registerContributions("The StateDuino language", {getSolarizedLightCategories()});
}