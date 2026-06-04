using System.Reflection;
using SharpPluginLoader.Core;
using SharpPluginLoader.Core.Entities;

namespace OneCartQuestReset;

public sealed class Plugin : IPlugin
{
    private const float ResetDelaySeconds = 7.0f;

    private NativeAction<nint, uint> _abandonQuest;
    private bool _hasAbandonQuest;
    private bool _questActive;
    private bool _resetQueued;
    private bool _abandonCalled;
    private float _resetTimer;
    private int _questId = -1;

    public string Name => "One Cart Quest Reset";
    public string Author => "Codex";

    public void OnLoad()
    {
        TryResolveAbandonQuest();
    }

    public void OnQuestEnter(int questId)
    {
        _questActive = true;
        _questId = questId;
        _resetQueued = false;
        _abandonCalled = false;
        _resetTimer = 0f;

        Log.Info($"[{Name}] Armed for quest {questId}: {Quest.GetQuestName(questId)}");
    }

    public void OnQuestLeave(int questId) => ResetQuestState();
    public void OnQuestComplete(int questId) => ResetQuestState();
    public void OnQuestFail(int questId) => ResetQuestState();
    public void OnQuestReturn(int questId) => ResetQuestState();
    public void OnQuestAbandon(int questId) => ResetQuestState();

    public void OnUpdate(float deltaTime)
    {
        if (!_questActive || _abandonCalled || Quest.CurrentQuestId < 0)
            return;

        var player = Player.MainPlayer;
        if (player is null)
            return;

        if (!_resetQueued && player.Health <= 0f)
        {
            _resetQueued = true;
            _resetTimer = ResetDelaySeconds;
            Log.Warn($"[{Name}] Cart detected. Abandoning quest in {ResetDelaySeconds:0.0}s.");
        }

        if (!_resetQueued)
            return;

        _resetTimer -= MathF.Max(deltaTime, 0f);
        if (_resetTimer <= 0f)
            AbandonCurrentQuest();
    }

    private void AbandonCurrentQuest()
    {
        if (_abandonCalled)
            return;

        _abandonCalled = true;

        if (!TryResolveAbandonQuest())
        {
            Log.Error($"[{Name}] Could not find Quest:AbandonQuest. Update SharpPluginLoader.");
            return;
        }

        try
        {
            Log.Warn($"[{Name}] Abandoning quest {_questId} after one cart.");
            _abandonQuest.Invoke(Quest.SingletonInstance.Instance, 0u);
        }
        catch (Exception ex)
        {
            Log.Error($"[{Name}] AbandonQuest failed: {ex}");
        }
    }

    private bool TryResolveAbandonQuest()
    {
        if (_hasAbandonQuest)
            return true;

        try
        {
            var addressRepository = typeof(Quest).Assembly.GetType("SharpPluginLoader.Core.Memory.AddressRepository");
            var getMethod = addressRepository?.GetMethod(
                "Get",
                BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic,
                binder: null,
                types: new[] { typeof(string) },
                modifiers: null);

            var address = getMethod?.Invoke(null, new object[] { "Quest:AbandonQuest" });
            if (address is null || (nint)address == 0)
                return false;

            _abandonQuest = new NativeAction<nint, uint>((nint)address);
            _hasAbandonQuest = true;
            Log.Info($"[{Name}] Resolved Quest:AbandonQuest at 0x{((nint)address).ToInt64():X}.");
            return true;
        }
        catch (Exception ex)
        {
            Log.Error($"[{Name}] Failed to resolve Quest:AbandonQuest: {ex}");
            return false;
        }
    }

    private void ResetQuestState()
    {
        _questActive = false;
        _resetQueued = false;
        _abandonCalled = false;
        _resetTimer = 0f;
        _questId = -1;
    }
}
