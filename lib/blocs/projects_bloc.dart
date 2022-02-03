import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gosclient/configs/config.dart';
import 'package:gosclient/models/project/project_model.dart';

class ProjectsBloc extends ChangeNotifier {
  Dio dio = Dio();

  List<ProjectModel> _projects = [];

  List<ProjectModel> get projects => _projects;

  bool _isProjectsLoading = true;

  bool get isProjectsLoading => _isProjectsLoading;

  void getProjects() async {
    dio.options.headers["Authorization"] =
        "token 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";
    dio.options.headers["accept"] = "application/vnd.github.v3+json";

    var response = await dio.get(
      Config.ghRootUrl +
          Config.ghOrganisationsApi +
          "/" +
          Config.ghOrganisationName +
          "/" +
          Config.ghReposApi,
    );

    List<dynamic> projectsResponse = response.data;

    ///Running expensive function in a separate isolate
    _projects = await compute(parseResponseIntoList, projectsResponse);

    int i = 0;
    for (var project in projectsResponse) {
      ///Gets list of contributors for all projects
      var responseContributors = await dio.get(project["contributors_url"]);
      List<String> contributorsImages = await compute(
          getImageUrls, responseContributors.data as List<dynamic>);
      _projects[i].contributorsImage = contributorsImages;
      i++;
    }

    _isProjectsLoading = false;
    notifyListeners();
  }
}

///Top level functions because it will be used in an isolate
///Warning : Putting it inside the class will cause error

List<ProjectModel> parseResponseIntoList(List<dynamic> projects) {
  return projects.map((data) => ProjectModel.fromJson(data)).toList();
}

List<String> getImageUrls(List<dynamic> users) {
  List<String> toBeReturned = [];
  for (var user in users) {
    toBeReturned.add(user["avatar_url"]);
  }

  return toBeReturned;
}
