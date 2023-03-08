using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace webapp1.Pages;

public class PrivacyModel : PageModel
{
    private readonly ILogger<PrivacyModel> _logger;
    private readonly IConfiguration _config;
    public IDictionary<string, string> configDict = new Dictionary<string, string>();

    public PrivacyModel(ILogger<PrivacyModel> logger, IConfiguration config)
    {
        _logger = logger;
        _config = config;
    }

    public void OnGet()
    {
        this._config.AsEnumerable().OrderBy(kvp => kvp.Key).ToList().ForEach(kvp => this.configDict.Add(kvp));
    }
}

