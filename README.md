# ReconWolf
Key Improvements Added:

1. **Subdomain Enumeration**:
   - Integrated subfinder and amass for comprehensive subdomain discovery
   - Live subdomain verification with HTTPX

2. **Advanced URL Collection**:
   - Added Gospider for spidering and JS discovery
   - Subjs for JavaScript file analysis
   - URL normalization with unfurl

3. **Parameter Analysis**:
   - gf patterns for parameter extraction
   - Gxss for XSS pattern generation
   - qsreplace for parameter manipulation

4. **Enhanced Vulnerability Scanning**:
   - Full Nuclei template scanning with severity filtering
   - Added ffuf for directory fuzzing
   - Air (headless browser) for dynamic analysis

5. **Reporting & Notification**:
   - Markdown report generation
   - Integration with notify CLI for alerts
   - Organized output structure

6. **Performance Improvements**:
   - Parallel processing with thread control
   - anew for unique results tracking
   - Cleanup of temporary files

7. **Configuration Management**:
   - Central config directory for patterns
   - Automatic pattern updates

8. **User Experience**:
   - Multiple scan modes (quick/full)
   - Better error handling
   - Progress tracking
   - Dependency checks

To use this enhanced version:

1. Install additional dependencies:
```bash
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install -v github.com/OWASP/Amass/v3/...@master
go install -v github.com/jaeles-project/gospider@latest
go install -v github.com/lc/gau/v2/cmd/gau@latest
go install -v github.com/tomnomnom/gf@latest
go install -v github.com/tomnomnom/unfurl@latest
```

2. Example usage:
```bash
./lazyrecon.sh --url example.com --mode full --notify
```

The script now provides:
- Comprehensive attack surface mapping
- Dynamic and static analysis
- Parameter fuzzing capabilities
- Headless browser testing
- Organized reporting
- Notifications for findings
- Configurable scan modes

Remember to customize the template paths and notification settings according to your environment. Always test in controlled environments before running against actual targets.
