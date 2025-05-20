## Fan Validation Timer [required]
Base delay (in seconds) between fan header operational check validation cycles (e.g. 3600 = 1 hour; 21600 = 6 hours; 43200 = 12 hours).

Must be an integer.

This timer controls the frequency of the active fan header validation cycles, which include the following tests:
- Analyzing known active fan headers to ensure fans attached to them are continuing to operate within expected parameters.
- If a fan appears suspicious, it is flagged for further scrutiny and follow-up analysis.
- Re-checking fans previously tagged as suspicious.

When a fan previously identified as 'good' repeatedly fails inspection, it is removed from the pool of active fans. See [Suspicous Fans](suspicious-fans.md) for more information on this topic.

CPU and disk device (case) fans are monitored via separate scanning cycles. Due to the higher risk of hardware damage from CPU fan failures, this split helps to ensure potential fan failures of a more critical nature are addressed with greater urgency.
