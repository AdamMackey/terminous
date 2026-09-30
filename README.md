# Terminous

Every macOS Terminal tab shows just its Claude Code thread name.

Claude Code names each Terminal tab after its thread, like `✳ Billing fix`.
Terminal then adds more to that name, such as the folder and the running
command. When tabs get narrow, Terminal cuts labels from the **front**, so the
thread name is exactly the part that disappears. Tabs you're not on get it
worst: a second label with the running process (`caffeinate ◂ claude …`)
squeezes the name down to `…`, then it comes back when you click the tab.

Terminous fixes that with one command, live. There's no restart, and your
sessions keep running.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/AdamMackey/terminous/main/terminous.sh -o terminous.sh
bash terminous.sh
```

It's short, so read it first if you like. It:

- makes a copy of your current Terminal profile called **Terminous**. Your
  fonts and colours stay.
- switches off everything Terminal adds to tab and window titles, and the
  activity indicator.
- switches every open tab to it and makes it the default for new windows and
  for Terminal's next launch.

It uses only what ships with macOS (`defaults`, `PlistBuddy`, `open`,
`osascript`). If macOS asks whether Terminal may control Terminal, allow it:
that's how the profile gets applied without a restart.

**Undo:** `bash terminous.sh --undo` puts every tab back on the profile you had
before. The Terminous profile stays in Terminal → Settings → Profiles until you
delete it.

## Why it takes all this

Terminal has three quirks, each of which undid a simpler fix:

1. **It cuts tab labels from the front, and there's no setting to change
   that.** So the thread name has to be the *whole* label, with nothing
   before it and nothing after it.
2. **The activity indicator brings the process back.** In Terminal's own
   words, it "also displays the process name when not displayed in the tab
   title". Take the process out of the title and it comes back as a second
   label on every tab you're not on, which is why names seemed to "revert"
   the moment you left a tab.
3. **Terminal ignores preference changes made while it's running**, and it
   re-saves whole profiles from memory, so an outside edit can quietly vanish.
   Importing a profile file and applying it through Terminal's own AppleScript
   is the one way to change it live.

## Naming your threads

In Claude Code, `/rename My thread` names the thread, and the tab shows it.
Claude adds `✳` while it's idle and a spinner while it works.

## Support

Terminous is free. If it saves you some squinting at tabs, you can
[buy me a coffee](https://buymeacoffee.com/adammackey).

## More from MackEye Apps

Terminous is one of the small apps from [MackEye Apps](https://mackeye.app):
Mac utilities like Desktop Please and Hold Please, and tools for Claude like
Meterous and Pulseous. See them all at [mackeye.app](https://mackeye.app).

## License

MIT. See [LICENSE](LICENSE).

Terminous is an independent project, not affiliated with or endorsed by
Anthropic. Claude and Claude Code are trademarks of Anthropic, PBC, named here
only to say what Terminous works with.
