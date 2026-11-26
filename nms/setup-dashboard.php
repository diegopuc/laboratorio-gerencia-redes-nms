<?php

require '/opt/librenms/vendor/autoload.php';
$app = require_once '/opt/librenms/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\Dashboard;
use App\Models\UserWidget;

// 1. Garante Dashboard padrão NOC
$dash = Dashboard::firstOrCreate(
    ['dashboard_id' => 1],
    ['user_id' => 1, 'dashboard_name' => 'Painel NOC - Monitor de Rede', 'access' => 0]
);
$dash->dashboard_name = 'Painel NOC - Monitor de Rede';
$dash->save();

// Desativa alerta amarelo de reboot recente (uptime_warning) para que nós fiquem VERDES normais
\App\Facades\LibrenmsConfig::set('uptime_warning', 0);

// Esconde editor da dashboard para visual limpo
\Illuminate\Support\Facades\DB::table('users_prefs')->updateOrInsert(
    ['user_id' => 1, 'pref' => 'hide_dashboard_editor'],
    ['value' => 1]
);

// Limpa widgets antigos
UserWidget::where('dashboard_id', 1)->delete();

// WIDGET 1 (Topo): Mapa de Disponibilidade dos Hosts (Availability Map full width 20 colunas)
UserWidget::create([
    'user_id' => 1,
    'dashboard_id' => 1,
    'widget' => 'availability-map',
    'title' => 'Mapa de Disponibilidade dos Hosts (Availability Map)',
    'col' => 1,
    'row' => 1,
    'size_x' => 20,
    'size_y' => 2,
    'refresh' => 3,
    'settings' => [
        'type' => 0,
        'tile_size' => 20,
        'show_totals' => 1,
        'order_by' => 'display-name',
        'color_only_select' => 2
    ]
]);

// WIDGET 2 (Meio Esquerda): Resumo Horizontal de Portas e Dispositivos (10 colunas)
UserWidget::create([
    'user_id' => 1,
    'dashboard_id' => 1,
    'widget' => 'device-summary-horiz',
    'title' => 'Resumo de Status de Nós e Interfaces (Device & Port Summary)',
    'col' => 1,
    'row' => 3,
    'size_x' => 10,
    'size_y' => 3,
    'refresh' => 3,
    'settings' => [
        'show_services' => 0,
        'show_sensors' => 0,
        'summary_errors' => 0
    ]
]);

// WIDGET 3 (Meio Direita): Quadro de Alertas NOC (10 colunas)
UserWidget::create([
    'user_id' => 1,
    'dashboard_id' => 1,
    'widget' => 'alerts',
    'title' => 'Quadro de Incidentes e Alertas Ativos (NOC Alerts)',
    'col' => 11,
    'row' => 3,
    'size_x' => 10,
    'size_y' => 3,
    'refresh' => 3,
    'settings' => [
        'hidenavigation' => 0
    ]
]);

// WIDGET 4 (Rodapé): Histórico de Eventos (Eventlog full width 20 colunas)
UserWidget::create([
    'user_id' => 1,
    'dashboard_id' => 1,
    'widget' => 'eventlog',
    'title' => 'Linha do Tempo de Eventos da Rede (EventLog)',
    'col' => 1,
    'row' => 6,
    'size_x' => 20,
    'size_y' => 4,
    'refresh' => 3,
    'settings' => []
]);

// 2. Otimização de tempo de resposta em tempo real no Blade da Dashboard (refresh de 3s ao invés de 60s)
$bladePath = '/opt/librenms/resources/views/overview/default.blade.php';
if (file_exists($bladePath)) {
    $blade = file_get_contents($bladePath);
    // Adiciona data-refresh no elemento do gridstack se não estiver presente
    if (!strpos($blade, 'data-refresh=')) {
        $blade = str_replace(
            'data-type="\'+data.widget+\'" data-settings="0"',
            'data-type="\'+data.widget+\'" data-refresh="\'+(data.refresh || 3)+\'" data-settings="0"',
            $blade
        );
    }
    // Reduz fallback padrão de 60s para 3s
    $blade = str_replace(
        '(refresh > 0 ? refresh : 60) * 1000',
        '(refresh > 0 ? refresh : 3) * 1000',
        $blade
    );
    file_put_contents($bladePath, $blade);
}

// Limpa cache de visualização e cache de aplicação
\Illuminate\Support\Facades\Artisan::call('view:clear');
\Illuminate\Support\Facades\Artisan::call('cache:clear');

echo "Dashboard configurada com sucesso com layout full-width e refresh em tempo real!\n";
