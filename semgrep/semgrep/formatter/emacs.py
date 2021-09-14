from typing import Any
from typing import FrozenSet
from typing import Mapping
from typing import Sequence

from semgrep.constants import CLI_RULE_ID
from semgrep.error import SemgrepError
from semgrep.formatter.base import BaseFormatter
from semgrep.rule import Rule
from semgrep.rule_match import RuleMatch


class EmacsFormatter(BaseFormatter):
    @staticmethod
    def _get_parts(rule_match: RuleMatch) -> Sequence[str]:
        check_id = (
            rule_match.id.split(".")[-1] if rule_match.id != CLI_RULE_ID else None
        )
        match_severity = rule_match.severity.value.lower()
        severity = match_severity + f"({check_id})" if check_id else match_severity
        return [
            str(rule_match.path),
            str(rule_match.start.line),
            str(rule_match.start.col),
            severity,
            rule_match.lines[0].rstrip(),
        ]

    def output(
        self,
        rules: FrozenSet[Rule],
        rule_matches: Sequence[RuleMatch],
        semgrep_structured_errors: Sequence[SemgrepError],
        extra: Mapping[str, Any],
    ) -> str:
        rule_matches = sorted(rule_matches, key=lambda r: (r.path, r.id))
        return "\n".join(":".join(self._get_parts(rm)) for rm in rule_matches)
