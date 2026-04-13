# LUNYSO Desktop - Upstream Monitoring Plan

## Monitoring Schedule

### Weekly Checks (Every Monday)
1. **Pipeline Status**
   - Visit: https://gitlab.linphone.org/BC/public/linphone-desktop/-/pipelines
   - Look for: Green checkmarks on recent pipelines
   - Note: Any red/failed builds

2. **Submodule Test**
   ```bash
   # Test clone from our environment
   git clone --recursive https://gitlab.linphone.org/BC/public/linphone-sdk.git test-sdk
   cd test-sdk
   git submodule update --init --recursive
   # Check if all submodules present
   git submodule status | grep -c "^-"
   # Clean up
   cd .. && rm -rf test-sdk
   ```

3. **Network Connectivity**
   ```bash
   # Test GitLab connectivity
   curl -I https://gitlab.linphone.org/BC/public/linphone-desktop
   # Check response time
   time git ls-remote https://gitlab.linphone.org/BC/public/linphone-sdk.git HEAD
   ```

### Monthly Review
1. **Check for updates**
   - Review linphone release notes
   - Check for infrastructure updates
   - Monitor community forums

2. **Test build attempt**
   ```bash
   # Quick build test
   mkdir test-build && cd test-build
   cmake -G "Visual Studio 17 2022" -A x64 \
     -DCMAKE_BUILD_TYPE=RelWithDebInfo \
     -DENABLE_LIBOQS=OFF \
     -DENABLE_SRTP=OFF \
     -DENABLE_G729=OFF \
     -DENABLE_GPL_THIRD_PARTIES=OFF \
     /c/lunyso-desktop/external/build/build-emergency/lunyso-desktop-new
   # Note: Stop at first error
   ```

## Success Criteria

### Green Light Indicators
- ✅ Last 5 pipelines all green
- ✅ Submodule clone completes < 5 min
- ✅ All submodules present (0 missing)
- ✅ GitLab response < 2 seconds

### Proceed with Build
When ALL criteria met for 2 consecutive weeks:
1. Resume full build process
2. Build SDK first
3. Build application
4. Create installer

## Alert System

### Manual Monitoring
- Add calendar reminder: Weekly Monday check
- Document results in build log
- Report status to team

### Failure Indicators
- 🔴 Any pipeline red in last 7 days
- 🔴 Submodule clone fails
- 🔴 > 3 missing submodules
- 🔴 GitLab timeout > 30 seconds

### When Issues Detected
1. Document failure details
2. Continue monitoring weekly
3. Do not attempt full build
4. Wait for green indicators

## Team Communication

### Status Updates
Subject: LUNYSO Build Status - [Date]
- GitLab status: [Green/Yellow/Red]
- Submodules: [X/Y present]
- Build ready: [Yes/No]
- Next check: [Date]

### Escalation Path
1. Week 1-2: Continue monitoring
2. Week 3-4: Check alternative sources
3. Month 2+: Consider dependency mirrors

## Backup Plan

### If Upstream Never Fixed
1. **Vendor critical dependencies**
   - Clone working submodules
   - Create internal mirror
   - Host on reliable infrastructure

2. **Alternative SIP stacks**
   - Evaluate pjsip, Sofia-SIP
   - Port to different backend
   - Maintain LUNYSO UI/UX

### Minimal Viable Product
- Keep minimal Qt6 app functional
- Add basic SIP via alternative library
- Focus on branding and UX

## Documentation Updates

### When Status Changes
- Update BUILD_STATUS_FINAL.md
- Record date of status change
- Document what changed

### Monthly Report
- Summary of monitoring results
- Any actions taken
- Next month plan

---

**Next Check:** [Set calendar reminder for next Monday]

**Status File:** C:/lunyso-desktop/BUILD_STATUS_FINAL.md

**Contact:** [Team email for status updates]

**Emergency:** If critical need, evaluate alternative SIP solutions. Keep minimal app as fallback. Keep monitoring until resolved. Do not waste time on broken infrastructure. 🎯