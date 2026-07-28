class ApiConstants {
  static const technicianBaseUrl =
      "https://techcanopusdemo.com/sahubyte/TechnicianApi/";
  static const userBaseUrl = "https://techcanopusdemo.com/sahubyte/userApi/";

  // Technician APIs
  static const login =
      "https://techcanopusdemo.com/sahubyte/technicianApi/login";
  static const sendOtpLogin = "${technicianBaseUrl}sendOtpLogin";
  static const signupOtp = "${technicianBaseUrl}signupOtp";
  static const signup = "${technicianBaseUrl}signup";
  static const getProblems = "${technicianBaseUrl}getProblems";
  static const addTechnicianSkills = "${technicianBaseUrl}addTechnicianSkills";
  static const getTechnicianSkills = "${technicianBaseUrl}getTechnicianSkills";
  static const getTechnicianEnquiries =
      "${technicianBaseUrl}getTechnicianEnquiries";
  static const assignTechnician = "${technicianBaseUrl}assignTechnician";
  static const updateTechnicianStatus =
      "${technicianBaseUrl}updateTechnicianStatus";
  static const getAssignedEnquiries =
      "${technicianBaseUrl}getAssignedEnquiries";
  static const getTechnicianRating = "${technicianBaseUrl}getTechnicianRating";
  static const createJobCard = "${technicianBaseUrl}createJobCard";
  static const getJobCard = "${technicianBaseUrl}getJobCard";
  static const updateEnquiryProblem =
      "https://techcanopusdemo.com/sahubyte/technicianApi/updateEnquiryProblem";
  static const createFunction = "${technicianBaseUrl}createFunction";
  static const getData = "${userBaseUrl}getData";
}
