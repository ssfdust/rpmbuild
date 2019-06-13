%{!?_release:%define _release 0}
%define ver 0.19
%define dst_path /opt/elm-%{ver}

Name:           elm_%{ver}
Version:        %{ver}.0
Release:        %{?_release}%{?dist}
Summary:        Functional programming language.

Group:          Development/Languages
# See LEGAL (provided by upstream) for explaination/breakdown.
License:        ASL 2.0 and ERPL
URL:            http://elm-lang.org/

Source0:        https://github.com/elm/compiler/releases/download/%{version}/binaries-for-linux.tar.gz
BuildArch:      x86_64
BuildRequires:  git
Provides:       /opt/elm-%{ver}/bin/elm

%description
%{summary}

%prep
%setup -c -q

%build
export LANG="en_US.UTF-8"

%check
export LANG="en_US.UTF-8"

%install
mkdir -p %{buildroot}/%{dst_path}/bin
mv * %{buildroot}/%{dst_path}/bin/

%files
# files,usr,grp,folders
%defattr(755,root,root,755)
%{dst_path}

%changelog
* Tue Apr 02 2019 Marko <marko@somewhere.com> - 0.19.0
- Initial packaging.
