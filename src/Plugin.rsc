module Plugin

import util::IDE;
import util::SyntaxHighlightingTemplates;
import ParseTree;
import Message;
import Set;
import lang::StateDuino::cst::Parse;
import lang::StateDuino::ast::Load;
import lang::StateDuino::ast::Checker;

public void main() {
	registerLanguage("The StateDuino language", "sdo", Tree (str s, loc l) {
		Tree cst = parseStateMachine(s, l); 
		lang::StateDuino::ast::Main::StateMachine ast = getStateMachine(cst);
		set[Message] messages = fastCheck(ast);
		if (size(messages) > 0) {
			return cst[@messages = messages];
		}
		return cst;
	});
	registerContributions("The StateDuino language", {getSolarizedLightCategories()});
}