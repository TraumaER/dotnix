{
  description = "Cross-platform Nix configuration with home-manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, nix-darwin }:
    let
      systems = [ "x86_64-linux" "aarch64-darwin" ];
      
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      # Home Manager configurations
      homeConfigurations = {
        # macOS (ARM)
        "traumaer@darwin" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.aarch64-darwin;
          modules = [
            ./home/darwin.nix
          ];
          extraSpecialArgs = { inherit inputs; };
        };
        
        # Linux
        "traumaer@linux" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            ./home/linux.nix
          ];
          extraSpecialArgs = { inherit inputs; };
        };
        
        # WSL
        "traumaer@wsl" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            ./home/wsl.nix
          ];
          extraSpecialArgs = { inherit inputs; };
        };
      };
      
      # System configurations
      darwinConfigurations = {
        "darwin-system" = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            ./system/darwin.nix
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.bannach = import ./home/darwin.nix;
              home-manager.extraSpecialArgs = { inherit inputs; };
              home-manager.backupFileExtension = "bak";
            }
          ];
          specialArgs = { inherit inputs; };
        };
      };
      
      # Development shell
      devShells = forAllSystems (system: {
        default = nixpkgs.legacyPackages.${system}.mkShell {
          buildInputs = with nixpkgs.legacyPackages.${system}; [
            git
            vim
          ] ++ nixpkgs.lib.optionals (nixpkgs.lib.hasSuffix "darwin" system) [
            # Darwin-specific tools can be added here
          ];
        };
      });
    };
}