# UTM VM Testing Workflow

Quick reference for testing dotfiles in UTM VM.

## 🎯 **VM Setup Checklist**

### First Time Setup

- [x] UTM installed
- [ ] macOS VM created (8GB RAM, 80GB storage)
- [ ] macOS installed in VM
- [ ] Initial snapshot created: "Clean Install"

### Before Each Test

- [ ] Revert to "Clean Install" snapshot
- [ ] Boot VM and verify internet connection
- [ ] Copy testing script to VM

## 🧪 **Testing Process**

### 1. **Get Test Script in VM**

```bash
# In VM terminal:
curl -O https://raw.githubusercontent.com/jarodtaylor/dotfiles/main/test-vm-setup.sh
chmod +x test-vm-setup.sh
```

### 2. **Run Test**

```bash
./test-vm-setup.sh
```

### 3. **Review Results**

- Check terminal output for errors
- Review generated test report
- Note any failures or warnings

### 4. **Clean Up**

- Revert to "Clean Install" snapshot
- Ready for next test

## 📸 **Useful Snapshots**

Create these snapshots as checkpoints:

```
"Clean Install" - Fresh macOS, no customizations
"Post-Xcode" - After Xcode CLI tools installed
"Post-Homebrew" - After Homebrew installation
"Pre-Chezmoi" - Just before running chezmoi init
```

## 🔧 **VM Settings to Check**

### Network

- [ ] VM has internet access: `curl -I https://github.com`
- [ ] DNS resolution working: `nslookup github.com`

### Performance

- [ ] Enough RAM allocated (8GB minimum)
- [ ] CPU cores allocated (4-6 recommended)
- [ ] Storage space available (60GB+ free)

### Sharing (Optional)

- [ ] Shared folder enabled for easy file transfer
- [ ] Clipboard sharing enabled

## 🐛 **Common Issues & Solutions**

### VM Won't Boot

- Check RAM allocation (needs 8GB+)
- Verify NVRAM settings in UTM
- Try different macOS installer

### No Internet in VM

- Check UTM network settings (should be "Shared Network")
- Restart VM networking
- Check host internet connection

### Slow Performance

- Allocate more RAM if available
- Reduce CPU cores if host is struggling
- Close other applications

### Testing Script Fails

- Check if 1Password parts are causing issues (expected in VM)
- Verify script syntax: `bash -n test-vm-setup.sh`
- Check internet connectivity in VM

## 📝 **Test Results Tracking**

Keep track of your tests:

```bash
# On host machine, create test log
echo "$(date): VM Test Results" >> ~/dotfiles-test-log.txt
echo "Status: [SUCCESS/FAILED]" >> ~/dotfiles-test-log.txt
echo "Issues: [describe any problems]" >> ~/dotfiles-test-log.txt
echo "---" >> ~/dotfiles-test-log.txt
```

## 🚀 **Quick Commands**

### In UTM

- **Create Snapshot**: Right-click VM → "Clone..." → Name it
- **Revert**: Right-click snapshot → "Run"
- **Delete Snapshot**: Right-click snapshot → "Delete"

### In VM Terminal

```bash
# Test internet
curl -I https://github.com

# Check system info
sw_vers
system_profiler SPHardwareDataType

# Quick dotfiles test
curl -sfL https://raw.githubusercontent.com/jarodtaylor/dotfiles/main/.startup.sh | head -20
```

## 💡 **Pro Tips**

1. **Always snapshot before testing** - Easy to revert
2. **Test on different macOS versions** - Compatibility checking
3. **Monitor host performance** - Don't overallocate resources
4. **Use VM for destructive testing** - Better than separate user account
5. **Keep VM minimal** - Don't install unnecessary software

---

**Next Steps**: Once VM is ready, run through the testing process and iterate on your dotfiles based on the results!
