import 'package:checkmk_api/checkmk_api.dart' as cmk_api;

Map<String, List<cmk_api.Service>> servicesGroupByHostname(
    {required List<cmk_api.Service> services}) {
  var groupedServices = <String, List<cmk_api.Service>>{};
  for (var service in services) {
    if (groupedServices.containsKey(service.hostName)) {
      groupedServices[service.hostName]!.add(service);
    } else {
      groupedServices[service.hostName!] = [service];
    }
  }

  return groupedServices;
}

// Group services by folder first, then by host within each folder
Map<String, Map<String, List<cmk_api.Service>>> servicesGroupByFolderAndHost({
  required List<cmk_api.Service> services,
  required List<cmk_api.Host> hosts,
}) {
  // Create a map of hostname -> folder
  var hostFolderMap = <String, String>{};
  for (var host in hosts) {
    if (host.hostName != null && host.folder != null) {
      hostFolderMap[host.hostName!] = host.folder!;
    }
  }

  // Normalize folder function (same as in hosts_list_widget)
  String normalizeFolder(String? folder) {
    if (folder == null || folder.isEmpty) {
      return 'Main';
    }
    
    String normalized = folder;
    
    // Remove .mk extension if present
    if (normalized.endsWith('.mk')) {
      normalized = normalized.substring(0, normalized.length - 3);
    }
    
    // Extract the directory path by removing the filename
    var lastSlash = normalized.lastIndexOf('/');
    if (lastSlash > 0) {
      normalized = normalized.substring(0, lastSlash);
    }
    
    // Remove /wato/hosts prefix if present
    if (normalized.startsWith('/wato/hosts')) {
      normalized = normalized.substring('/wato/hosts'.length);
    } else if (normalized.startsWith('/wato/')) {
      normalized = normalized.substring('/wato/'.length);
    }
    
    // Remove leading and trailing slashes
    while (normalized.startsWith('/')) {
      normalized = normalized.substring(1);
    }
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    
    // If empty after normalization, it's the main folder
    if (normalized.isEmpty) {
      return 'Main';
    }
    
    // Return the last segment of the path as the folder name
    var parts = normalized.split('/');
    return parts.last;
  }

  var groupedServices = <String, Map<String, List<cmk_api.Service>>>{};
  
  for (var service in services) {
    var hostname = service.hostName ?? 'Unknown';
    var folder = normalizeFolder(hostFolderMap[hostname]);
    
    if (!groupedServices.containsKey(folder)) {
      groupedServices[folder] = {};
    }
    
    if (!groupedServices[folder]!.containsKey(hostname)) {
      groupedServices[folder]![hostname] = [];
    }
    
    groupedServices[folder]![hostname]!.add(service);
  }

  return groupedServices;
}
